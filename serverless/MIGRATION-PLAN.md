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

Deployment instructions — manual (Terraform CLI) and GitHub Actions, with prerequisites — live in [`README.md`](./README.md).

## Folder Structure

```
serverless/
├── ARCHITECTURE.md
├── MIGRATION-PLAN.md
├── README.md                # Deployment guide (manual + GitHub Actions)
└── infra/
    ├── main/                # Root module - deploys everything at once
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── ssm.tf
    │   └── terraform.tf
    ├── deploy-role/         # GitHub Actions OIDC role for app code deploys
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── infra-role/          # GitHub Actions OIDC role for provisioning this stack
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tf
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
