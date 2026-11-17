# Complete ECR Example

Demonstrates every feature of the module:

- Private repositories with KMS encryption, lifecycle policies, cross-account read/read-write access and Lambda read access
- A public repository (ECR Public) with catalog data
- Enhanced registry scanning with `SCAN_ON_PUSH` and `CONTINUOUS_SCAN` rules
- Cross-region registry replication
- Pull-through cache rules for Docker Hub, GitHub Container Registry and ECR Public

> ECR Public is only available in `us-east-1`, so keep `region = "us-east-1"` (or move `public_repositories` to a module instance that uses a `us-east-1` provider).
> The Docker Hub and GitHub pull-through cache rules need a `credential_arn` (Secrets Manager secret prefixed with `ecr-pullthroughcache/`) to be applied successfully.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

With the defaults the private repositories are named `ause1-ecr-prod-platform-<key>` and the public repository `prod-platform-cli`.

## Inputs

| Name           | Description                         | Type     | Default       |
| -------------- | ----------------------------------- | -------- | ------------- |
| `region`       | AWS region for the provider         | `string` | `"us-east-1"` |
| `account_name` | Account name used in resource names | `string` | `"prod"`      |
| `project_name` | Project name used in resource names | `string` | `"platform"`  |

## Outputs

| Name                                | Description                          |
| ----------------------------------- | ------------------------------------ |
| `repository_urls`                   | Map of repository keys to URLs       |
| `repository_arns`                   | Map of repository keys to ARNs       |
| `repositories_summary`              | Summary of all private repositories  |
| `registry_scanning_configuration`   | Registry scanning configuration      |
| `registry_pull_through_cache_rules` | Pull through cache rules             |
| `public_repository_uris`            | Map of public repository keys to URIs |
| `public_repositories_summary`       | Summary of all public repositories   |
