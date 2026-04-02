flowchart TD
    USER["User"] -->|"HTTPS"| CF

    subgraph CloudFront["CloudFront Distribution"]
        CF["CloudFront<br/><i>PriceClass_100<br/>redirect-to-https</i>"]
    end

    subgraph Frontend["Frontend Tier"]
        S3["S3 Bucket<br/><i>Private, SSE-AES256<br/>Versioning enabled</i>"]
        OAC["Origin Access Control<br/><i>SigV4 signing</i>"]
    end

    subgraph Backend["Backend Tier"]
        APIGW["API Gateway HTTP API<br/><i>CORS enabled<br/>JSON access logs</i>"]
        LAMBDA["Lambda Function<br/><i>Rust ARM64 (Graviton2)<br/>provided.al2023<br/>128 MB / 10s timeout</i>"]
        ALIAS["Lambda Alias<br/><i>live</i>"]
    end

    subgraph Database["Database Tier"]
        DDB["DynamoDB Table<br/><i>PAY_PER_REQUEST<br/>PK/SK + GSI1<br/>SSE / PITR enabled</i>"]
    end

    subgraph IAM["IAM"]
        ROLE["Lambda Execution Role<br/><i>CloudWatch Logs<br/>DynamoDB CRUD</i>"]
    end

    subgraph Observability["Observability"]
        CW_LAMBDA["CloudWatch Logs<br/><i>/aws/lambda/*</i>"]
        CW_APIGW["CloudWatch Logs<br/><i>/aws/apigateway/*</i>"]
    end

    CF -->|"/* static assets<br/>cached 1h"| OAC
    OAC --> S3
    CF -->|"/api/* no cache<br/>all headers forwarded"| APIGW
    APIGW -->|"ANY /api/{proxy+}<br/>GET /api (health)"| ALIAS
    ALIAS --> LAMBDA
    LAMBDA -->|"GetItem / PutItem<br/>Query / Scan"| DDB
    ROLE -.->|"AssumeRole"| LAMBDA
    LAMBDA -.-> CW_LAMBDA
    APIGW -.-> CW_APIGW

    style CloudFront fill:#e8f4f8,stroke:#2196F3
    style Frontend fill:#e8f5e9,stroke:#4CAF50
    style Backend fill:#fff3e0,stroke:#FF9800
    style Database fill:#fce4ec,stroke:#E91E63
    style IAM fill:#fff8e1,stroke:#FFC107
    style Observability fill:#f3e5f5,stroke:#9C27B0