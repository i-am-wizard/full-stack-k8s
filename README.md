# full-stack-k8s

## 🚀 Local Deployment with kind

### 1. Create the Cluster

```bash
kind create cluster --config kind-cluster.yaml
kubectl create namespace dev
```

### 2. Pull and load Docker Images into kind

```bash
docker pull ghcr.io/i-am-wizard/word-manager-backend:1.0.0-15
docker pull ghcr.io/i-am-wizard/word-manager-frontend:1.0.0-5
docker pull postgres:latest

kind load docker-image ghcr.io/i-am-wizard/word-manager-frontend:1.0.0-15
kind load docker-image ghcr.io/i-am-wizard/word-manager-backend:1.0.0-5
kind load docker-image postgres:latest
```

### 3. Deploy with Helm

```bash
helm install three-tier-app . \
  --namespace dev \
  --values values-kind.yaml
```

### 4. Verify the Deployment

```bash
kubectl get all -n dev
```

### 5. Access the Frontend

```bash
kubectl port-forward service/frontend 8080:80 -n dev
```

Then open [http://localhost:8080](http://localhost:8080) in your browser.

## ☁️ Deployment on AWS EKS

Infrastructure is deployed via two GitHub Actions workflows (manual trigger):

- **`infra-deploy.yml`** — Run `plan` to preview or `apply` to provision infra + deploy Helm chart
- **`infra-destroy.yml`** — Manual-only teardown (type `destroy` to confirm)

#### Prerequisites (one-time setup)

**1. Create S3 bucket for Terraform state**

```bash
aws s3api create-bucket \
  --bucket full-stack-k8s-tfstate \
  --region eu-west-2 \
  --create-bucket-configuration LocationConstraint=eu-west-2

aws s3api put-bucket-versioning \
  --bucket full-stack-k8s-tfstate \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket full-stack-k8s-tfstate \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

**2. Create IAM role for GitHub Actions infra deploys**

The OIDC provider should already exist. Apply the EKS OIDC stack to create the IAM role
trusted by this repo for EKS + VPC + Helm deploy:

```bash
cd infra/eks-oidc
terraform init
terraform plan
terraform apply
```

Note the `infra_role_arn` output — you'll need it for the next step.

**3. Migrate Terraform state to S3**

If you have existing local state in `infra/eks/`, migrate it:

```bash
cd infra/eks
terraform init -migrate-state
```

**4. Configure GitHub repository secrets**

In repo settings → Secrets and variables → Actions, add:

| Secret              | Description                                    |
|---------------------|------------------------------------------------|
| `AWS_INFRA_ROLE_ARN`| ARN of `github-actions-infra-deploy` IAM role |
| `DB_NAME`           | Postgres database name (e.g. `hello_db`)       |
| `DB_USER`           | Postgres username                              |
| `DB_PASSWORD`       | Postgres password                              |

**5. Publish container images**

Ensure the latest images are pushed by triggering green builds in:
- https://github.com/i-am-wizard/word-manager-be/actions
- https://github.com/i-am-wizard/word-manager-fe/actions

#### Accessing the application

After a successful deploy, get the ELB hostname:

```bash
kubectl get svc -n ingress-nginx
```

Find the `EXTERNAL-IP` of the `ingress-nginx-controller` service and paste it into the browser.

---

### Manual deployment

<details>
<summary>Click to expand manual steps</summary>

***This assumes you have access to AWS, have terraform and kubectl installed***

#### 1. Create ECR with Github OIDC

```bash
cd infra/ecr-oidc
terraform init
terraform plan
terraform apply
```

#### 2. Provision cluster via Terraform

```bash
cd infra/eks
terraform init
terraform plan
terraform apply
aws eks update-kubeconfig --name three-tier-eks --region eu-west-2
```

#### 3. Create dev namespace

```bash
kubectl create namespace dev
```

#### 4. Create DB Credentials

```bash
kubectl create secret generic postgres-auth \
  --namespace dev \
  --from-literal=POSTGRES_DB=hello_db \
  --from-literal=POSTGRES_USER=change-user \
  --from-literal=POSTGRES_PASSWORD=change-password \
  --from-literal=SPRING_DATASOURCE_USERNAME=change-user \
  --from-literal=SPRING_DATASOURCE_PASSWORD=change-password
```

#### 5. Publish images

Rerun latest green builds of:
- https://github.com/i-am-wizard/word-manager-be/actions
- https://github.com/i-am-wizard/word-manager-fe/actions

Ensure builds are green

#### 6. Deploy with Helm

***Install Nginx Ingress Controller (Required for Ingress)***
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/aws/deploy.yaml
```

***Export repository urls and run helm chart***

```bash
cd ../..

export REPO_URL_BE=$(aws ecr describe-repositories  --repository-names word-manager-backend --region eu-west-2 --query "repositories[].repositoryUri" --output=text)

export REPO_URL_FE=$(aws ecr describe-repositories  --repository-names word-manager-frontend --region eu-west-2 --query "repositories[].repositoryUri" --output=text)

helm install three-tier-app ./chart \
  --namespace dev \
  --values ./chart/values-eks.yaml \
  --set backend.image.repository="$REPO_URL_BE" \
  --set frontend.image.repository="$REPO_URL_FE"
```

#### 7. Verify the Deployment

```bash
kubectl get all -n dev
```

#### 8. Get ELB hostname to access the front end

```bash
kubectl get svc -n ingress-nginx
```
Find the `EXTERNAL-IP` of the `ingress-nginx-controller` service and paste it into the browser.

#### 9. Teardown

To avoid "DependencyViolation" errors when destroying Terraform you **must** delete the Load Balancer first.

```bash
helm uninstall three-tier-app --namespace dev

kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/aws/deploy.yaml

cd infra/eks
terraform destroy
```

</details>

test