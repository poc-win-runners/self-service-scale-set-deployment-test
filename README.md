# Self-Service ARC Scale Set Deployment

Template-based self-service system for deploying GitHub Actions Runner Controller scale sets on AWS EKS.

## Folder Structure

```
self-service-deployment/
├── .github/workflows/
│   └── deploy-scaleset.yml           # Deployment workflow
├── templates/
│   └── windows-standard/
│       ├── config.scaleset.yaml      # Base Helm values template
│       └── template.parameters.json  # Parameter definitions
├── deployments/
│   ├── team-a-runners.json           # Active deployment configurations
│   └── team-b-runners.json
├── snapshots/
│   └── [timestamp snapshots]         # Auto-generated deployment history
├── scripts/
│   ├── load-config.sh                # Configuration loader
│   ├── setup-arc-controller.sh       # Controller setup
│   ├── prepare-values.sh             # Values file generator
│   └── save-deployment.sh            # Snapshot creator
└── README.md
```

## Quick Start

### Step 1: Copy Template Parameters

Copy the template parameters file and fill in your values:

```bash
cp templates/windows-standard/template.parameters.json deployments/my-team-runners.json
```

Edit `deployments/my-team-runners.json` with your configuration:

```json
[
  {
    "ParameterKey": "TemplateName",
    "ParameterValue": "windows-standard"
  },
  {
    "ParameterKey": "TemplatePath",
    "ParameterValue": "templates/windows-standard/config.scaleset.yaml"
  },
  {
    "ParameterKey": "ScaleSetName",
    "ParameterValue": "my-team-runners"
  },
  {
    "ParameterKey": "RunnersNamespace",
    "ParameterValue": "my-team"
  },
  {
    "ParameterKey": "RunnerLabels",
    "ParameterValue": "windows,my-team"
  },
  {
    "ParameterKey": "AWSRegion",
    "ParameterValue": "eu-central-1"
  },
  {
    "ParameterKey": "ClusterName",
    "ParameterValue": "arc-cluster"
  },
  {
    "ParameterKey": "GitHubConfigURL",
    "ParameterValue": "https://github.com/your-org"
  }
]
```

### Step 2: Commit Configuration

```bash
git add deployments/my-team-runners.json
git commit -m "Add my-team-runners configuration"
git push
```

### Step 3: Deploy

1. Go to Actions tab in GitHub
2. Select "Deploy Scale Set" workflow
3. Enter your configuration file name: `my-team-runners.json`
4. Select operation (deploy/upgrade/uninstall)
5. Run workflow

> **Note:** Just provide the filename! The workflow automatically searches in both `deployments/` and `snapshots/` folders. If the file doesn't exist, it will show available options.

## Prerequisites

### Required GitHub Secrets

Set these in GitHub repository settings (Settings > Secrets and variables > Actions > Secrets):

- `AWS_ROLE_NAME` - AWS IAM role name for OIDC authentication
- `AWS_ACCOUNT_ID` - AWS Account ID
- `GH_APP_ID` - GitHub App ID
- `GH_INSTALLATION_ID` - GitHub App Installation ID
- `GH_PRIVATE_KEY` - GitHub App Private Key (PEM format, multiline)

> **Security Note:** These sensitive credentials are stored as GitHub secrets and injected at runtime. They are never committed to the repository, even in deployment snapshots.

### AWS & EKS Setup

- EKS cluster running with Windows node groups
- OIDC identity provider configured
- IAM role with permissions for GitHub Actions

## How It Works

### Architecture

- **Configuration-driven**: All parameters stored in JSON files
- **Namespace isolation**: Each team gets `arc-{namespace}` namespace
- **Shared controller**: Single ARC controller in `arc-systems` namespace
- **Deployment history**: Auto-commits deployment snapshots to `deployments/`

### Deployment Flow

1. Reads configuration from `deployments/{config}.json`
2. Extracts template path and loads base template from `templates/{template}/config.scaleset.yaml`
3. Checks/installs ARC controller if needed
4. Creates namespace and GitHub App secret
5. Configures RBAC for controller access
6. Merges user configuration with base template using `yq`
7. Deploys scale set using Helm
8. Commits deployment snapshot to `deployments/{timestamp}-{name}.json`

### Template Structure

Each template folder contains:
- `config.scaleset.yaml` - Base Helm values for the scale set
- `template.parameters.json` - Parameter schema with descriptions and defaults

To create a new template:
1. Copy `templates/windows-standard/` to `templates/{new-template}/`
2. Modify `config.scaleset.yaml` with your Kubernetes specifications
3. Update `template.parameters.json` with required parameters
4. Users can now reference your template in their deployment configs

### Configuration Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `TemplateName` | Template identifier | `windows-standard` |
| `TemplatePath` | Path to base template | `templates/windows-standard/config.scaleset.yaml` |
| `ScaleSetName` | Name for the scale set release | `team-a-runners` |
| `RunnersNamespace` | Namespace suffix (becomes `arc-{value}`) | `team-a` |
| `RunnerImage` | Container image for runners | `ghcr.io/poc-win-runners/arc-windows-runner:v2.329.0` |
| `RunnerGroup` | GitHub runner group | `default` |
| `RunnerLabels` | Comma-separated labels | `windows,team-a` |
| `MinRunners` | Minimum number of runners | `0` |
| `MaxRunners` | Maximum number of runners | `10` |
| `AWSRegion` | AWS region | `eu-central-1` |
| `ClusterName` | EKS cluster name | `arc-cluster` |
| `ARCSystemsNamespace` | ARC controller namespace | `arc-systems` |
| `GitHubSecretName` | Secret name for GitHub App | `gha-runner-secret` |
| `GitHubConfigURL` | GitHub org or repo URL | `https://github.com/poc-win-runners` |

> **Note:** Sensitive parameters (AWS credentials, GitHub App credentials) are provided via GitHub Secrets and not stored in configuration files.

## Operations

### Deploy New Scale Set

Select `deploy` operation. Creates new scale set with configuration.

### Upgrade Existing Scale Set

Select `upgrade` operation. Updates existing scale set with new configuration.

### Uninstall Scale Set

Select `uninstall` operation. Removes scale set and cleans up resources.

## Deployment Snapshots

Every successful deployment or upgrade automatically creates a snapshot in the `snapshots/` folder with:
- Complete configuration used
- Timestamp of deployment
- ARC controller version
- Operation performed

Snapshots are named: `YYYY-MM-DD-HHMMSS-{scaleset-name}.json`

### Redeploying from Snapshot

Simply use the snapshot filename in the workflow:

```
2025-11-12-120000-team-a-runners.json
```

The workflow will automatically find it in the `snapshots/` folder. No need to specify the full path!

## Adding New Templates

To add a new runner template (e.g., for Linux or custom configuration):

1. Create new folder: `templates/{template-name}/`
2. Copy structure from `templates/windows-standard/`
3. Modify `config.scaleset.yaml` with your specifications
4. Update `template.parameters.json` with required parameters
5. Users reference it via `TemplateName` and `TemplatePath` in their deployment configs

## Checking Deployment

```bash
kubectl get pods -n arc-NAMESPACE

helm list -n arc-NAMESPACE

kubectl logs -n arc-NAMESPACE -l app.kubernetes.io/name=gha-runner-scale-set
```

## Troubleshooting

**Runners not appearing:**
- Verify `GitHubConfigURL` matches your GitHub org/repo
- Check GitHub App credentials
- Review pod logs

**Permission errors:**
- Verify IAM role and OIDC configuration
- Check RBAC bindings
- Ensure controller service account exists

**Configuration not found:**
- Verify file path is correct
- Ensure file is committed to repository
- Check JSON syntax is valid

## Scripts

### load-config.sh

Parses JSON configuration file and exports environment variables.

**Usage:**

```bash
./scripts/load-config.sh deployments/team-a-runners.json
```

**Exports:**

- `SCALESET_NAME`, `RUNNERS_NAMESPACE`, `AWS_REGION`, `CLUSTER_NAME`
- `ARC_SYSTEMS_NS`, `ARC_RUN_NS`, `TEMPLATE_PATH`
- `RUNNER_IMAGE`, `GITHUB_CONFIG_URL`, `GITHUB_SECRET_NAME`
- `RUNNER_GROUP`, `RUNNER_LABELS`, `MIN_RUNNERS`, `MAX_RUNNERS`

**Note:** Sensitive credentials (AWS_ROLE_NAME, AWS_ACCOUNT_ID, GH_APP_ID, GH_INSTALLATION_ID, GH_PRIVATE_KEY) are set by the workflow from GitHub secrets, not from the config file.

### setup-arc-controller.sh

Checks for existing ARC controller or installs new one.

**Usage:**

```bash
export ARC_SYSTEMS_NS="arc-systems"
./scripts/setup-arc-controller.sh
```

**Exports:**

- `CONTROLLER_VERSION` - Installed or existing controller version
- `CONTROLLER_SERVICE_ACCOUNT` - Service account name for the controller

### prepare-values.sh

Merges configuration parameters with base template using yq.

**Usage:**

```bash
export TEMPLATE_PATH="templates/windows-standard/config.scaleset.yaml"
export CONTROLLER_SERVICE_ACCOUNT="arc-gha-rs-controller"
export RUNNER_IMAGE="ghcr.io/poc-win-runners/arc-windows-runner:v2.329.0"
./scripts/prepare-values.sh
```

**Output:** Creates `values-scaleset.yaml` ready for Helm deployment

### save-deployment.sh

Creates deployment snapshot with metadata and commits to repository.

**Usage:**

```bash
export SCALESET_NAME="team-a-runners"
export CONTROLLER_SERVICE_ACCOUNT="arc-gha-rs-controller"
export CONTROLLER_VERSION="0.9.3"
./scripts/save-deployment.sh deployments/team-a-runners.json deploy
```

**Output:** Creates timestamped snapshot in `deployments/` and commits to git

## Testing Locally

To test scripts locally without running the full workflow:

```bash
export GITHUB_ENV=/tmp/github_env
export ARC_SYSTEMS_NS=arc-systems

./scripts/load-config.sh deployments/team-a-runners.json

source /tmp/github_env

echo "Loaded configuration for: $SCALESET_NAME"
```

## Error Handling

All scripts use `set -euo pipefail` for strict error handling:
- `-e` - Exit on error
- `-u` - Exit on undefined variable
- `-o pipefail` - Exit if any command in pipeline fails
