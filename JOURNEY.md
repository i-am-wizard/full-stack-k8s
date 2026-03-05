# My Kubernetes Learning Journey

> A chronological walkthrough of building a production-grade three-tier application on Kubernetes — from a local `kind` cluster to a fully automated AWS EKS deployment with Terraform and GitHub Actions.

---

## Learning Timeline

```mermaid
timeline
    title From Local Cluster to Production EKS
    section Phase 1 — Local Dev
        kind cluster setup          : Created a 4-node kind cluster (1 control-plane, 3 workers)
        Helm chart authoring        : Built a reusable Helm chart for the 3-tier app
        Init containers             : Added initContainer to wait for Postgres before backend starts
        k3s on Raspberry Pi         : Experimented with resource tuning on bare-metal ARM nodes
    section Phase 2 — AWS Infra
        Terraform for EKS           : Provisioned a managed EKS cluster with VPC and node groups
        ECR repositories            : Created private container registries for frontend and backend
        GitHub OIDC                 : Replaced long-lived AWS keys with short-lived OIDC tokens
        DRY refactoring             : Consolidated duplicate IAM/OIDC code and restructured files
    section Phase 3 — Stateful Storage
        StatefulSet for Postgres    : Migrated Postgres from Deployment to StatefulSet with PVCs
        EBS CSI Driver              : Installed the EBS CSI addon for dynamic gp3 volume provisioning
        Storage classes             : Created a default gp3 StorageClass for the cluster
    section Phase 4 — Networking
        Ingress resource            : Replaced NodePort/LoadBalancer with a proper Ingress resource
        NGINX Ingress Controller    : Deployed the NGINX Ingress Controller with AWS ELB integration
        VPC subnet tagging          : Tagged public subnets for automatic ELB discovery by Kubernetes
    section Phase 5 — CI/CD
        Deploy workflow             : Built a GitHub Actions workflow for plan/apply with Helm deploy
        Destroy workflow            : Built a safe teardown workflow with ELB/ENI cleanup guards
        IAM hardening               : Scoped down IAM permissions for the infra deploy role
```

---

## Git Flow

The project evolved through feature branches and pull requests. Here is the branching history:

```mermaid
gitgraph
    commit id: "6d2066c" tag: "initContainers"
    commit id: "b406a1f" tag: "image builds"
    commit id: "ff5e5bf" tag: "README fix"
    commit id: "371f642" tag: "k3s resources"
    commit id: "0e7a5be" tag: "EKS Terraform"
    commit id: "81fd79b" tag: "ECR + OIDC"
    commit id: "a284014" tag: "DRY OIDC"
    commit id: "82d10c8" tag: "restructure"
    branch feature/add-storage-class
    commit id: "a4c56b0" tag: "StatefulSet"
    checkout main
    merge feature/add-storage-class id: "10983d1" tag: "PR #1"
    branch feature/change-vpc-file
    commit id: "ad1226b" tag: "Ingress"
    checkout main
    commit id: "cd81bab" tag: "Ingress merge"
    commit id: "3b19305" tag: "teardown docs"
    branch feature/github-action-infra
    commit id: "fdf9c88" tag: "GH Actions"
    checkout main
    merge feature/github-action-infra id: "f58aa0a" tag: "PR #2"
    commit id: "cac8bb3" tag: "IAM cleanup"
    commit id: "490ac75" tag: "HEAD"
```

---

## Phase 1 — Local Development with kind

The journey started with getting a three-tier application running locally. I set up a 4-node `kind` cluster (1 control-plane + 3 workers), wrote a Helm chart from scratch, and figured out how to wire frontend, backend, and Postgres together using Kubernetes Services. One of the first real challenges was the startup ordering problem — the Spring Boot backend would crash if Postgres wasn't ready yet. Adding an `initContainer` with a simple `nc` (netcat) check solved that elegantly. I also briefly experimented with deploying to a k3s cluster on a Raspberry Pi, which taught me about resource constraints on low-powered hardware.

**Key commits:** `6d2066c` → `371f642`

---

## Phase 2 — AWS Infrastructure with Terraform

Moving from local to cloud meant learning Terraform. I provisioned an EKS cluster using the `terraform-aws-modules/eks/aws` module, set up a VPC with public subnets across two availability zones, and created ECR repositories for the container images. Instead of storing AWS access keys as GitHub Secrets, I learned to use GitHub's OIDC provider to assume IAM roles with short-lived credentials — a much more secure approach. As the Terraform codebase grew, I refactored it for DRY principles and restructured files into logical directories (`infra/eks/`, `infra/ecr-oidc/`, `infra/eks-oidc/`).

**Key commits:** `0e7a5be` → `82d10c8`

---

## Phase 3 — Stateful Storage

Postgres doesn't belong in a stateless Deployment. I learned this the hard way and migrated it to a StatefulSet with `volumeClaimTemplates` for persistent storage. On AWS, this required the EBS CSI Driver addon and a custom `gp3` StorageClass set as the cluster default. The StatefulSet guarantees stable network identity (`postgres-0`) and persistent volume binding, so data survives pod restarts and rescheduling.

**Key commits:** `a4c56b0` (branch: `feature/add-storage-class`, merged via PR #1)

---

## Phase 4 — Networking with Ingress

Initially, the frontend was exposed via a `NodePort` service. That's fine for local development but not for production. I replaced it with a Kubernetes Ingress resource backed by the NGINX Ingress Controller. On AWS, the Ingress Controller automatically provisions an Elastic Load Balancer. For this to work, the VPC public subnets needed the `kubernetes.io/role/elb: "1"` tag so the controller could discover them. I also cleaned up the old k3s-specific chart values and documented the full teardown process (delete Helm release → delete Ingress Controller → Terraform destroy) to avoid orphaned AWS resources.

**Key commits:** `cd81bab` → `3b19305` (branch: `feature/change-vpc-file`)

---

## Phase 5 — CI/CD with GitHub Actions

The final phase automated everything. I built two GitHub Actions workflows — one for deploying (`infra-deploy.yml`) and one for tearing down (`infra-destroy.yml`). Both use OIDC to authenticate with AWS, eliminating the need for long-lived credentials. The deploy workflow supports two modes: `plan` (preview changes) and `apply` (provision infra + deploy the Helm chart). The destroy workflow includes safety guards — it waits for ELB and ENI cleanup before running `terraform destroy` to avoid dependency errors. After the initial implementation, I hardened the IAM permissions to follow least-privilege principles.

**Key commits:** `fdf9c88` → `cac8bb3` (branch: `feature/github-action-infra`, merged via PR #2)

---

## Application Architecture

```mermaid
flowchart TD
    subgraph Ingress["Ingress Layer"]
        ING["Ingress<br/><i>nginx class</i>"]
    end

    subgraph Frontend["Frontend Tier"]
        FE_SVC["frontend Service<br/><i>ClusterIP :80</i>"]
        FE_DEPLOY["frontend Deployment<br/><i>Nginx container</i>"]
    end

    subgraph Backend["Backend Tier"]
        BE_SVC["backend Service<br/><i>ClusterIP :8080</i>"]
        BE_DEPLOY["backend Deployment<br/><i>Spring Boot</i>"]
        INIT["initContainer<br/><i>wait-for-postgres</i>"]
    end

    subgraph Database["Database Tier"]
        PG_SVC["postgres-svc<br/><i>Headless Service :5432</i>"]
        PG_SS["postgres StatefulSet<br/><i>PostgreSQL 16</i>"]
        PVC["PVC<br/><i>1Gi gp3 volume</i>"]
    end

    subgraph Config["Configuration"]
        SECRET["postgres-auth Secret<br/><i>DB credentials</i>"]
    end

    ING -->|"/ → port 80"| FE_SVC
    FE_SVC --> FE_DEPLOY
    FE_DEPLOY -->|"API calls /api/*"| BE_SVC
    BE_SVC --> BE_DEPLOY
    INIT -.->|"nc -z postgres-svc 5432"| PG_SVC
    BE_DEPLOY -->|"JDBC :5432"| PG_SVC
    PG_SVC --> PG_SS
    PG_SS --- PVC

    SECRET -.->|"envFrom"| BE_DEPLOY
    SECRET -.->|"envFrom"| PG_SS

    style Ingress fill:#e8f4f8,stroke:#2196F3
    style Frontend fill:#e8f5e9,stroke:#4CAF50
    style Backend fill:#fff3e0,stroke:#FF9800
    style Database fill:#fce4ec,stroke:#E91E63
    style Config fill:#f3e5f5,stroke:#9C27B0
```

---

## AWS Infrastructure

```mermaid
flowchart TD
    subgraph GitHub["GitHub"]
        REPO_INFRA["i-am-wizard/full-stack-k8s<br/><i>Infrastructure repo</i>"]
        REPO_FE["i-am-wizard/word-manager-fe<br/><i>Frontend repo</i>"]
        REPO_BE["i-am-wizard/word-manager-be<br/><i>Backend repo</i>"]
        GHA_DEPLOY["infra-deploy.yml<br/><i>Plan / Apply</i>"]
        GHA_DESTROY["infra-destroy.yml<br/><i>Teardown</i>"]
    end

    subgraph OIDC["IAM OIDC Trust"]
        ROLE_INFRA["github-actions-infra-deploy<br/><i>EKS + VPC + Helm</i>"]
        ROLE_ECR["github-actions-ecr-main<br/><i>ECR push/pull</i>"]
    end

    subgraph AWS_Infra["AWS — eu-west-2"]
        S3["S3 Bucket<br/><i>full-stack-k8s-tfstate</i>"]

        subgraph VPC["VPC 10.0.0.0/16"]
            SUB_A["Public Subnet<br/><i>10.0.1.0/24 — eu-west-2a</i>"]
            SUB_B["Public Subnet<br/><i>10.0.2.0/24 — eu-west-2b</i>"]

            subgraph EKS["EKS Cluster — three-tier-eks"]
                NG["Managed Node Group<br/><i>t3.medium × 2-4<br/>ON_DEMAND</i>"]
                ADDONS["Addons<br/><i>CoreDNS · kube-proxy<br/>VPC-CNI · EBS CSI</i>"]
                SC["StorageClass<br/><i>gp3 (default)</i>"]
                NGINX_IC["NGINX Ingress Controller"]
            end
        end

        ELB["AWS ELB<br/><i>auto-provisioned</i>"]

        subgraph ECR["ECR Repositories"]
            ECR_FE["word-manager-frontend"]
            ECR_BE["word-manager-backend"]
        end
    end

    REPO_INFRA --> GHA_DEPLOY
    REPO_INFRA --> GHA_DESTROY
    GHA_DEPLOY -->|"OIDC"| ROLE_INFRA
    GHA_DESTROY -->|"OIDC"| ROLE_INFRA
    REPO_FE -->|"OIDC"| ROLE_ECR
    REPO_BE -->|"OIDC"| ROLE_ECR
    ROLE_INFRA --> EKS
    ROLE_INFRA --> S3
    ROLE_ECR --> ECR
    NGINX_IC --> ELB
    ELB --> SUB_A
    ELB --> SUB_B
    NG --- SUB_A
    NG --- SUB_B

    style GitHub fill:#f5f5f5,stroke:#333
    style OIDC fill:#fff8e1,stroke:#FFC107
    style AWS_Infra fill:#e3f2fd,stroke:#1565C0
    style VPC fill:#e8f5e9,stroke:#2E7D32
    style EKS fill:#fff3e0,stroke:#E65100
    style ECR fill:#fce4ec,stroke:#C62828
```

---

## CI/CD Pipeline

```mermaid
flowchart LR
    subgraph Deploy["infra-deploy.yml"]
        direction TB
        TRIGGER_D["Manual Trigger<br/><i>plan or apply</i>"]

        subgraph Plan["plan"]
            direction TB
            P1["Checkout"] --> P2["OIDC Auth"]
            P2 --> P3["terraform init"]
            P3 --> P4["terraform plan"]
        end

        subgraph Apply["apply"]
            direction TB
            A1["Checkout"] --> A2["OIDC Auth"]
            A2 --> A3["terraform init"]
            A3 --> A4["terraform apply"]
            A4 --> A5["Update kubeconfig"]
            A5 --> A6["Create namespace<br/>+ DB secret"]
            A6 --> A7["Install NGINX<br/>Ingress Controller"]
            A7 --> A8["Helm upgrade<br/>--install"]
            A8 --> A9["Verify<br/>deployment"]
        end

        TRIGGER_D -->|"plan"| Plan
        TRIGGER_D -->|"apply"| Apply
    end

    subgraph Destroy["infra-destroy.yml"]
        direction TB
        TRIGGER_X["Manual Trigger<br/><i>type 'destroy'</i>"]
        X1["Checkout"] --> X2["OIDC Auth"]
        X2 --> X3["Update kubeconfig"]
        X3 --> X4["Helm uninstall"]
        X4 --> X5["Delete NGINX<br/>Ingress Controller"]
        X5 --> X6["Wait for ELB<br/>+ ENI cleanup"]
        X6 --> X7["terraform destroy"]
        TRIGGER_X --> X1
    end

    style Deploy fill:#e8f5e9,stroke:#2E7D32
    style Destroy fill:#ffebee,stroke:#C62828
    style Plan fill:#e3f2fd,stroke:#1565C0
    style Apply fill:#e8f5e9,stroke:#388E3C
```

---

## Tech Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Nginx (container) | Static file serving + reverse proxy |
| **Backend** | Spring Boot (Java) | REST API |
| **Database** | PostgreSQL 16 | Persistent data store |
| **Orchestration** | Kubernetes (kind / EKS) | Container orchestration |
| **Packaging** | Helm | Kubernetes manifest templating |
| **Infrastructure** | Terraform | VPC, EKS, ECR, IAM provisioning |
| **CI/CD** | GitHub Actions | Automated deploy and teardown |
| **Auth** | GitHub OIDC → AWS IAM | Keyless cloud authentication |
| **Registry** | AWS ECR + GitHub GHCR | Container image storage |
| **Storage** | AWS EBS (gp3) | Persistent volumes for Postgres |
| **Networking** | NGINX Ingress Controller + AWS ELB | External traffic routing |
| **State** | S3 (versioned, encrypted) | Terraform remote state |
