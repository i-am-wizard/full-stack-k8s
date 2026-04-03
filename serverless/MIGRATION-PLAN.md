# Migration Plan: Kubernetes → AWS Serverless

> **Status:** INFRASTRUCTURE COMPLETE
> **Created:** 2026-03-08
> **Branch:** `feature/go-serverless`
> **Scope:** Infrastructure only - application code (Rust backend, frontend) is deployed from separate repositories

## Overview

Migrate the full-stack-k8s project from EKS (Java/Spring Boot + PostgreSQL + Nginx) to a fully serverless AWS architecture:

- **Frontend** → S3 + CloudFront (secure OAC-only access)
- **Backend** → API Gateway (HTTP API) + Lambda (Rust ARM64 - rewrite from Java)
- **Database** → DynamoDB (on-demand capacity)
- **Infrastructure** → Terraform modules (no Helm, no K8s)
- **CI/CD** → Lives in the separate frontend/backend application repositories

## Phases

### Phase 1 - Frontend: S3 + CloudFront ✅
- `serverless/infra/modules/frontend/` - S3 bucket, CloudFront, OAC
- No public S3 access; CloudFront is the only entry point
- SPA routing via custom error response (403/404 → /index.html)
- CloudFront proxies `/api/*` to API Gateway (no caching, all headers forwarded)

### Phase 2 - Database: DynamoDB ✅
- `serverless/infra/modules/database/` - DynamoDB single-table design
- PK/SK composite key + GSI1 (GSI1PK/GSI1SK)
- On-demand capacity (pay-per-request), SSE enabled, PITR enabled

### Phase 3 - Backend: API Gateway + Lambda ✅
- `serverless/infra/modules/backend/` - HTTP API, Lambda, integration
- Rust compiled to native ARM64 binary on `provided.al2023` runtime (~10-50ms cold starts)
- Single Lambda with API Gateway proxy integration (`ANY /api/{proxy+}`)
- Placeholder zip for initial deploy - real binary uploaded by CI/CD via `aws lambda update-function-code`

### Phase 4 - IAM, Composition & Layers ✅
- `serverless/infra/modules/iam/` - Lambda execution role (least-privilege: CloudWatch Logs + DynamoDB CRUD)
- `serverless/infra/main/` - Root module composing all modules (single `terraform apply`)
- `serverless/infra/layers/` - Per-layer deployable roots for independent testing
- `serverless/infra/deploy-role/` - GitHub Actions OIDC role for application deployments (S3 sync, CloudFront invalidation, Lambda code update)

### Phase 5 - Cleanup & Documentation
- Archive K8s-specific files
- Update README.md and JOURNEY.md

## Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 1 | Lambda runtime | Rust on `provided.al2023` (ARM64) | Native binary - ~10-50ms cold starts, minimal memory, no JVM overhead |
| 2 | Database | DynamoDB (on-demand) | Fully serverless, zero maintenance, pay-per-request |
| 3 | Lambda strategy | Single Lambda (proxy) | Simpler deployment, one Rust binary, API GW routes all /api/* |
| 4 | Frontend CDN | CloudFront + OAC | S3 never exposed publicly, HTTPS enforced |
| 5 | Deployment model | Layers (independent) + main (all-at-once) | Layers allow testing each tier in isolation; main for full-stack deploy |
| 6 | Deploy role | Separate TF root (`deploy-role/`) | Mirrors existing `infra/ecr-oidc/` pattern; independently managed |
| 7 | Repo scope | Infrastructure only | Application code (Rust backend, frontend) deployed from their own repositories |

## Deployment

### Prerequisites - Create S3 bucket for Terraform state (one-time)
```bash
export TF_STATE_BUCKET="my-actual-bucket-name"
export TF_VAR_frontend_bucket_name="my-globally-unique-name"

aws s3api create-bucket \
  --bucket $TF_STATE_BUCKET \
  --region eu-west-2 \
  --create-bucket-configuration LocationConstraint=eu-west-2

aws s3api put-bucket-versioning \
  --bucket $TF_STATE_BUCKET \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket $TF_STATE_BUCKET \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

### Deploy infrastructure
```bash
cd serverless/infra/main

terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=serverless/terraform.tfstate" \
  -backend-config="region=eu-west-2"

terraform plan
terraform apply
```

### Destroy infrastructure
```bash
cd serverless/infra/main
terraform destroy

#optional: to delete TF state bucket
aws s3 rb s3://$TF_STATE_BUCKET --force
```

### Deploy role (independent, run once)

> The deploy role is separate from both main/ and layers/ deployments. It creates the GitHub Actions OIDC role that allows your application repositories to deploy code (S3 sync, CloudFront invalidation, Lambda code update). Deploy this before deploying applications from your FE/BE repos.

```bash
cd serverless/infra/deploy-role
terraform init && terraform plan && terraform apply
```

### Destroy deploy role
```bash
cd serverless/infra/deploy-role
terraform destroy
```

### Layer-by-layer deployment (alternative, for independent testing)

> This is a separate deployment method using local state. Each layer is its own Terraform root with its own state file. Do not use both main/ and layers/ against the same AWS account - they create the same resources and will conflict.

```bash
cd serverless/infra/layers/database
terraform init
terraform plan
terraform apply

cd ../iam
terraform init
terraform plan
terraform apply

cd ../backend
terraform init
terraform plan
terraform apply

cd ../frontend
terraform init
terraform plan
terraform apply
```

Destroy order: `frontend, backend, iam, database`

## Folder Structure

```
serverless/
├── ARCHITECTURE.md
├── MIGRATION-PLAN.md
└── infra/
    ├── main/                # Root module - deploys everything at once
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tf
    ├── deploy-role/         # GitHub Actions OIDC role for app deploys
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── layers/              # Per-layer roots for independent testing
    │   ├── database/
    │   ├── iam/
    │   ├── backend/
    │   └── frontend/
    └── modules/             # Reusable child modules (the actual resources)
        ├── frontend/        (S3 + CloudFront)
        ├── backend/         (API Gateway + Lambda)
        ├── database/        (DynamoDB)
        └── iam/             (Lambda execution role)
```
