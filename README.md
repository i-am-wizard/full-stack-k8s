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

---

## 🐔 Deployment on K3S

***This assumes you have k3s setup ready***

### 1. Deploy with Helm

```bash
helm install three-tier-app . \
  --namespace dev \
  --values values-k3s.yaml
```

## ☁️ Deployment on AWS EKS

***This assumes you have access to AWS, have terraform and kubectl installed, Github actions and settings configured***

### 1. Create ECR with Github OIDC

```bash
cd infra/ecr-oidc
terraform init
terraform plan
terraform apply
```

### 1. Provision cluster via Terraform

```bash
cd infra/eks
terraform init
terraform plan
terraform apply
aws eks update-kubeconfig --name three-tier-eks --region eu-west-2
```

### 2. Ensure dev namespace exists

```bash
kubectl create namespace dev
```

### 3. Create DB Credentials as k8s secret

```bash
kubectl create secret generic postgres-auth \
  --namespace dev \
  --from-literal=POSTGRES_DB=hello_db \
  --from-literal=POSTGRES_USER=change-user \
  --from-literal=POSTGRES_PASSWORD=change-password \
  --from-literal=SPRING_DATASOURCE_USERNAME=change-user \
  --from-literal=SPRING_DATASOURCE_PASSWORD=change-password
```

### 4. Deploy with Helm

***Before running helm ensure <aws_account_id> is set in values-eks.yaml***

```bash
helm upgrade --install three-tier-app ./chart \
  --namespace dev \
  --values values-eks.yaml
```

### 4. Verify the Deployment

```bash
kubectl get all -n dev
```

### 5. Get ELB hostname to access the front end

```bash
kubectl get svc -n dev
```
copy `EXTERNAL-IP` and paste into the browser