resource "kubernetes_manifest" "secret_store" {
  manifest = yamldecode(<<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-west-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
YAML
  )

  depends_on = [helm_release.external_secrets]
}

resource "kubernetes_manifest" "postgres_external_secret" {
  manifest = yamldecode(<<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: postgres-auth
  namespace: dev
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: SecretStore
    name: aws-secrets
  target:
    name: postgres-auth
  data:
    - secretKey: POSTGRES_DB
      remoteRef:
        key: three-tier/postgres
        property: POSTGRES_DB
    - secretKey: POSTGRES_USER
      remoteRef:
        key: three-tier/postgres
        property: POSTGRES_USER
    - secretKey: POSTGRES_PASSWORD
      remoteRef:
        key: three-tier/postgres
        property: POSTGRES_PASSWORD
    - secretKey: SPRING_DATASOURCE_USERNAME
      remoteRef:
        key: three-tier/postgres
        property: SPRING_DATASOURCE_USERNAME
    - secretKey: SPRING_DATASOURCE_PASSWORD
      remoteRef:
        key: three-tier/postgres
        property: SPRING_DATASOURCE_PASSWORD
YAML
  )

  depends_on = [
    helm_release.external_secrets,
    kubernetes_manifest.secret_store
  ]
}