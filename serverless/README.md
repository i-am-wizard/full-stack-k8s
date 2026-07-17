# Word Manager — Serverless Deployment

Deployment guide for the serverless AWS stack: **S3 + CloudFront** (frontend), **API Gateway HTTP API + Lambda** (Rust backend), and **DynamoDB**.

- Architecture diagram: [`ARCHITECTURE.md`](./ARCHITECTURE.md)
- Design rationale and history: [`MIGRATION-PLAN.md`](./MIGRATION-PLAN.md)
- Application code (Rust backend, React frontend) is deployed from its own repositories, not from here.

There are two ways to deploy the infrastructure:

- **[Manual (Terraform CLI)](#manual-deployment-terraform-cli)** — run the Terraform roots directly.
- **[GitHub Actions](#github-actions-deployment)** — a plan/apply workflow for repeatable deploys.

Shared configuration:

| Setting | Value |
|---------|-------|
| Region | `eu-west-2` |
| Project name | `word-manager` |
| Terraform state bucket | `word-manager-serverless-infra-ak` |
| Terraform state key (`main/`) | `serverless/terraform.tfstate` |

---

## Prerequisites (one-time)

- Terraform >= 1.5 and AWS credentials with permission to create IAM roles and S3 buckets (Steps 1–2 create the IAM roles and the state bucket).
- A **globally unique** frontend bucket name that **starts with `word-manager-`** (S3 access is scoped to `word-manager-*`), e.g. `word-manager-frontend-<account-id>`.

---

## Manual deployment (Terraform CLI)

Run the three roots in order. Steps 1–2 use local state; Step 3 uses the S3 backend created in Step 1.

### Step 1 — Provisioning role and Terraform state bucket

```bash
cd serverless/infra/infra-role
terraform init
terraform plan
terraform apply
```

Creates the `github-actions-serverless-infra` role and the `word-manager-serverless-infra-ak` state bucket. Note the outputs:

- `role_arn` — set as the `AWS_SERVERLESS_INFRA_ROLE_ARN` secret in `full-stack-k8s` (for the GitHub Actions workflow).
- `tfstate_bucket_name` — the state bucket used in Step 3.

### Step 2 — Application deploy role

```bash
cd serverless/infra/deploy-role
terraform init
terraform plan
terraform apply
```

Creates the `github-actions-serverless-deploy` role. Set its `role_arn` output as the `AWS_DEPLOY_ROLE_ARN` secret in `word-manager-fe` and `word-manager-rust-be`.

### Step 3 — Deploy the stack

```bash
export TF_VAR_frontend_bucket_name="word-manager-frontend-<account-id>"
cd serverless/infra/main

terraform init \
  -backend-config="bucket=word-manager-serverless-infra-ak" \
  -backend-config="key=serverless/terraform.tfstate" \
  -backend-config="region=eu-west-2" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform plan
terraform apply
```

### Destroy the stack

```bash
cd serverless/infra/main
terraform destroy
```

### Layer-by-layer deployment (alternative, for independent testing)

> A separate method using local state — each layer is its own Terraform root with its own state file. Do **not** use both `main/` and `layers/` against the same AWS account; they create the same resources and will conflict.

```bash
cd serverless/infra/layers/database
terraform init && terraform plan && terraform apply

cd ../iam
terraform init && terraform plan && terraform apply

cd ../backend
terraform init && terraform plan && terraform apply

cd ../frontend
terraform init && terraform plan && terraform apply
```

Destroy order: `frontend, backend, iam, database`.

---

## GitHub Actions deployment

Workflow: [`.github/workflows/serverless-deploy.yml`](../.github/workflows/serverless-deploy.yml). It runs `terraform plan`/`apply` against `serverless/infra/main` using S3-native state locking, assuming the dedicated provisioning role via OIDC.

### Prerequisites

1. Run **Step 1** (Manual deployment) once, then set the `role_arn` output as the repo secret **`AWS_SERVERLESS_INFRA_ROLE_ARN`**. This also creates the state bucket.
2. Set the repo variable **`FRONTEND_BUCKET_NAME`** to a globally-unique `word-manager-*` bucket name.
3. The GitHub **OIDC provider** (`token.actions.githubusercontent.com`) exists in the account — already present from the EKS/ECR OIDC roles.

### Run it

**Actions → "Serverless Infrastructure: Plan & Deploy" → Run workflow**, then choose:

- `plan` — shows the Terraform diff (no changes applied).
- `apply` — provisions the stack and writes the outputs to the job summary.

> Manual runs must target the **`main`** branch — the role trust only allows `refs/heads/main`.

### After the infrastructure exists — application deploys

Once `main/` is applied, the stack publishes its outputs to SSM Parameter Store under `/word-manager/*`, and the application repos deploy themselves on push to `main`:

- **Backend** — `word-manager-rust-be/.github/workflows/deploy.yml` (builds the Rust Lambda, updates function code, shifts the `live` alias).
- **Frontend** — `word-manager-fe/.github/workflows/deploy-frontend.yml` (builds the Vite app, syncs to S3, invalidates CloudFront).

Both read their configuration from SSM and assume the app deploy role (`AWS_DEPLOY_ROLE_ARN`).
