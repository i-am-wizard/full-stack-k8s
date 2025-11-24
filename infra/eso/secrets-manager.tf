resource "aws_secretsmanager_secret" "postgres" {
  name = "three-tier/postgres"
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id

  secret_string = jsonencode({
    POSTGRES_DB                = "hello_db"
    POSTGRES_USER              = "user"
    POSTGRES_PASSWORD          = "password"
    SPRING_DATASOURCE_USERNAME = "user"
    SPRING_DATASOURCE_PASSWORD = "password"
  })
}
