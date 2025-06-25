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

### 1. Deploy with Helm

```bash
helm install three-tier-app . \
  --namespace dev \
  --values values-k3s.yaml
```

## ☁️ Deployment on AWS EKS

*(Instructions coming soon)*
