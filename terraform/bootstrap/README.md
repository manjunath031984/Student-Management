# Terraform state bucket bootstrap

This directory creates the GCS bucket used as the remote Terraform backend.

Bucket: `gcp-dev-july-2026-terraform-state`

Enabled:

- Object versioning
- Uniform bucket-level access
- Public access prevention (`enforced`)

State prefixes (configured in `terraform/backend/*.tfbackend`):

| Environment | Prefix   |
|-------------|----------|
| DEV         | `gke/dev`  |
| QA          | `gke/qa`   |
| PROD        | `gke/prod` |

## Apply once (local state) or via Jenkins

This bootstrap stack uses local state on purpose (chicken-and-egg).

Jenkins creates the bucket idempotently (if missing) before `terraform init` of the main stack.

Manual:

```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
```

After the bucket exists, initialize the main stack:

```bash
cd terraform
terraform init -backend-config=backend/dev.tfbackend
```

Do not store service-account JSON, passwords, or tokens in this directory.
