# Basic ECR Example

Creates three private ECR repositories (`api`, `worker`, `frontend`) with the module defaults: `IMMUTABLE` tags (except `worker`), AES256 encryption, scan on push and a default repository policy that grants read access to the account root.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

With the defaults (`us-east-1`, `account_name = "dev"`, `project_name = "myapp"`) the repositories are named:

- `ause1-ecr-dev-myapp-api`
- `ause1-ecr-dev-myapp-worker`
- `ause1-ecr-dev-myapp-frontend`

## Inputs

| Name           | Description                         | Type     | Default       |
| -------------- | ----------------------------------- | -------- | ------------- |
| `region`       | AWS region for the provider         | `string` | `"us-east-1"` |
| `account_name` | Account name used in resource names | `string` | `"dev"`       |
| `project_name` | Project name used in resource names | `string` | `"myapp"`     |

## Outputs

| Name                   | Description                    |
| ---------------------- | ------------------------------ |
| `repository_urls`      | Map of repository keys to URLs |
| `repository_arns`      | Map of repository keys to ARNs |
| `repositories_summary` | Summary of all repositories    |
