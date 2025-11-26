# Fedlin GCP Project Configuration

## Issue

The scripts were connecting to the wrong GCP project (`slplab-app` instead of the Fedlin project).

## Solution

### Option 1: Set Project via Environment Variable

```bash
export GCP_PROJECT="your-fedlin-project-id"
./google-workspace-dkim.sh fedlin.com
```

### Option 2: Set gcloud Default Project

```bash
# List projects to find Fedlin project
gcloud projects list

# Set the Fedlin project as default
gcloud config set project YOUR-FEDLIN-PROJECT-ID

# Verify
gcloud config get-value project
```

### Option 3: Use Setup Script

```bash
./setup-fedlin-project.sh
```

This interactive script will:
1. Show current project
2. List available projects
3. Let you select/set the Fedlin project
4. Set up application-default credentials

## Updated Scripts

All scripts now respect the `GCP_PROJECT` environment variable:

- `google-workspace-dkim.sh` - Uses GCP_PROJECT if set
- `google_dkim.py` - Uses GCP_PROJECT if set
- Falls back to gcloud default project if not specified

## Quick Start

```bash
# Set Fedlin project
export GCP_PROJECT="your-fedlin-project-id"

# Or set gcloud default
gcloud config set project your-fedlin-project-id

# Set Cloudflare token
export CLOUDFLARE_API_TOKEN="your-token"

# Run DKIM setup
./google-workspace-dkim.sh fedlin.com
```

## Finding Your Fedlin Project ID

If you're not sure of the project ID:

```bash
# List all projects
gcloud projects list

# Look for project with "fedlin" in name or ID
gcloud projects list --filter="name:fedlin OR projectId:fedlin"
```

## Verification

After setting the project, verify:

```bash
# Check current project
gcloud config get-value project

# Should show your Fedlin project ID
```

