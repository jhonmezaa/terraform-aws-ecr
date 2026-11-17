# AWS ECR Terraform Module

Terraform module to create and manage **AWS Elastic Container Registry (ECR)** repositories with full feature support.

## Features

- **Multiple private repositories** via `for_each` (add/remove without recreating others)
- **Multiple public repositories** with catalog data support
- **Repository policies** with auto-generated IAM policies (read, read-write, Lambda access, custom statements)
- **Lifecycle policies** for image retention management
- **Registry scanning** (BASIC or ENHANCED) with configurable scan rules
- **Cross-region/cross-account replication**
- **Pull-through cache rules** for Docker Hub, GitHub, ECR Public, and other registries
- **Registry-level IAM policies**
- **KMS encryption** support
- **Automatic naming convention** following `{region_prefix}-ecr-{account_name}-{project_name}-{key}`, overridable per repository with `name`
- **Per-resource region** (`region`, AWS provider v6) to manage resources outside the provider region
- **Centralized tagging** strategy

## Usage

### Basic - Multiple Private Repositories

```hcl
module "ecr" {
  source = "github.com/jhonmezaa/terraform-aws-ecr//ecr?ref=v1.2.0"

  account_name = "prod"
  project_name = "myapp"

  repositories = {
    api = {
      image_tag_mutability = "IMMUTABLE"
      image_scan_on_push   = true
    }

    worker = {
      image_tag_mutability = "IMMUTABLE"
      image_scan_on_push   = true
    }

    frontend = {
      image_tag_mutability = "MUTABLE"
    }
  }

  tags_common = {
    Environment = "production"
  }
}
```

This creates 3 repositories:

- `ause1-ecr-prod-myapp-api`
- `ause1-ecr-prod-myapp-worker`
- `ause1-ecr-prod-myapp-frontend`

### With KMS Encryption and Lifecycle Policy

```hcl
module "ecr" {
  source = "github.com/jhonmezaa/terraform-aws-ecr//ecr?ref=v1.2.0"

  account_name = "prod"
  project_name = "myapp"

  repositories = {
    api = {
      encryption_type    = "KMS"
      kms_key            = aws_kms_key.ecr.arn
      image_scan_on_push = true

      create_lifecycle_policy    = true
      repository_lifecycle_policy = jsonencode({
        rules = [
          {
            rulePriority = 1
            description  = "Expire untagged images older than 14 days"
            selection = {
              tagStatus   = "untagged"
              countType   = "sinceImagePushed"
              countUnit   = "days"
              countNumber = 14
            }
            action = { type = "expire" }
          },
          {
            rulePriority = 2
            description  = "Keep only last 30 tagged images"
            selection = {
              tagStatus     = "tagged"
              tagPrefixList = ["v"]
              countType     = "imageCountMoreThan"
              countNumber   = 30
            }
            action = { type = "expire" }
          }
        ]
      })
    }
  }
}
```

### With Cross-Account Access

```hcl
module "ecr" {
  source = "github.com/jhonmezaa/terraform-aws-ecr//ecr?ref=v1.2.0"

  account_name = "prod"
  project_name = "myapp"

  repositories = {
    api = {
      # Read access for dev account
      repository_read_access_arns = [
        "arn:aws:iam::111111111111:root"
      ]

      # Read-write access for CI/CD role
      repository_read_write_access_arns = [
        "arn:aws:iam::222222222222:role/ci-cd-deploy"
      ]

      # Lambda access for inference functions
      repository_lambda_read_access_arns = [
        "arn:aws:lambda:us-east-1:333333333333:function:my-function"
      ]
    }
  }
}
```

### With Registry Scanning (Enhanced)

```hcl
module "ecr" {
  source = "github.com/jhonmezaa/terraform-aws-ecr//ecr?ref=v1.2.0"

  account_name = "prod"
  project_name = "myapp"

  repositories = {
    api = {}
  }

  # Enable enhanced scanning
  manage_registry_scanning_configuration = true
  registry_scan_type                     = "ENHANCED"

  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter = [
        {
          filter      = "*"
          filter_type = "WILDCARD"
        }
      ]
    },
    {
      scan_frequency = "CONTINUOUS_SCAN"
      filter = [
        {
          filter      = "prod-*"
          filter_type = "WILDCARD"
        }
      ]
    }
  ]
}
```

### With Cross-Region Replication

```hcl
module "ecr" {
  source = "github.com/jhonmezaa/terraform-aws-ecr//ecr?ref=v1.2.0"

  account_name = "prod"
  project_name = "myapp"

  repositories = {
    api = {}
  }

  # Replicate to EU and APAC regions
  create_registry_replication_configuration = true

  registry_replication_rules = [
    {
      destinations = [
        {
          region      = "eu-west-1"
          registry_id = data.aws_caller_identity.current.account_id
        },
        {
          region      = "ap-southeast-1"
          registry_id = data.aws_caller_identity.current.account_id
        }
      ]
      repository_filters = [
        {
          filter      = "prod-"
          filter_type = "PREFIX_MATCH"
        }
      ]
    }
  ]
}
```

### With Pull-Through Cache

```hcl
module "ecr" {
  source = "github.com/jhonmezaa/terraform-aws-ecr//ecr?ref=v1.2.0"

  account_name = "prod"
  project_name = "myapp"

  repositories = {
    api = {}
  }

  # Cache images from upstream registries
  registry_pull_through_cache_rules = {
    docker-hub = {
      ecr_repository_prefix = "docker-hub"
      upstream_registry_url = "registry-1.docker.io"
    }
    github = {
      ecr_repository_prefix = "github"
      upstream_registry_url = "ghcr.io"
    }
    ecr-public = {
      ecr_repository_prefix = "ecr-public"
      upstream_registry_url = "public.ecr.aws"
    }
  }
}
```

### Public Repository

```hcl
module "ecr" {
  source = "github.com/jhonmezaa/terraform-aws-ecr//ecr?ref=v1.2.0"

  account_name = "prod"
  project_name = "myapp"

  public_repositories = {
    my-tool = {
      catalog_data = {
        description       = "My open source tool"
        about_text        = "A production-ready tool for..."
        architectures     = ["x86-64", "ARM 64"]
        operating_systems = ["Linux"]
      }
    }
  }
}
```

## Module Structure

```
terraform-aws-ecr/
├── ecr/
│   ├── 0-versions.tf              # Terraform and provider constraints
│   ├── 1-repository.tf            # Private ECR repositories
│   ├── 2-repository-policy.tf     # Repository IAM policies
│   ├── 3-lifecycle-policy.tf      # Image lifecycle policies
│   ├── 4-public-repository.tf     # Public ECR repositories
│   ├── 5-registry-scanning.tf     # Registry scanning configuration
│   ├── 6-registry-replication.tf  # Cross-region replication
│   ├── 7-pull-through-cache.tf    # Pull-through cache rules
│   ├── 8-registry-policy.tf       # Registry-level IAM policy
│   ├── 9-locals.tf                # Naming, region_prefix, tags
│   ├── 10-data.tf                 # Data sources
│   ├── 11-variables.tf            # Input variables
│   └── 12-outputs.tf              # Output values
└── examples/
    ├── basic/                     # Basic multi-repository example
    └── complete/                  # Full-featured example (private + public, registry features)
```

## Requirements

| Name      | Version  |
| --------- | -------- |
| terraform | >= 1.3   |
| aws       | >= 6.0   |

## Inputs

### Common Variables

| Name                | Description                                            | Type          | Default | Required |
| ------------------- | ------------------------------------------------------ | ------------- | ------- | -------- |
| `account_name`      | Account name for resource naming                       | `string`      | -       | yes      |
| `project_name`      | Project name for resource naming                       | `string`      | -       | yes      |
| `create`            | Master toggle to enable/disable all resources          | `bool`        | `true`  | no       |
| `region`            | Region where resources are managed (provider v6). Defaults to the provider region; also used to derive the region prefix | `string` | `null` | no |
| `region_prefix`     | Region prefix override (auto-derived if null)          | `string`      | `null`  | no       |
| `use_region_prefix` | Whether to include the region prefix in resource names | `bool`        | `true`  | no       |
| `tags_common`       | Common tags for all resources                          | `map(string)` | `{}`    | no       |

### Private Repositories

| Name           | Description                                  | Type                 | Default | Required |
| -------------- | -------------------------------------------- | -------------------- | ------- | -------- |
| `repositories` | Map of private ECR repository configurations | `map(object({...}))` | `{}`    | no       |

Each repository object supports:

| Key                                  | Description                                                    | Type           | Default       |
| ------------------------------------ | -------------------------------------------------------------- | -------------- | ------------- |
| `name`                               | Explicit repository name (overrides the naming convention)     | `string`       | `null`        |
| `image_tag_mutability`               | Tag mutability: MUTABLE, IMMUTABLE                             | `string`       | `"IMMUTABLE"` |
| `encryption_type`                    | Encryption type: AES256 or KMS                                 | `string`       | `"AES256"`    |
| `kms_key`                            | KMS key ARN. With `KMS` and `null`, the AWS managed key is used | `string`       | `null`        |
| `image_scan_on_push`                 | Scan images on push                                            | `bool`         | `true`        |
| `force_delete`                       | Force delete even with images                                  | `bool`         | `false`       |
| `attach_repository_policy`           | Attach a repository policy                                     | `bool`         | `true`        |
| `create_repository_policy`           | Auto-generate repository policy                                | `bool`         | `true`        |
| `repository_policy`                  | Pre-built policy JSON (required when attach is true and create_repository_policy is false) | `string` | `null` |
| `repository_read_access_arns`        | ARNs with read access                                          | `list(string)` | `[]`          |
| `repository_lambda_read_access_arns` | Lambda function ARNs with read access                          | `list(string)` | `[]`          |
| `repository_read_write_access_arns`  | ARNs with read-write access                                    | `list(string)` | `[]`          |
| `repository_policy_statements`       | Custom IAM policy statements                                   | `map(object)`  | `null`        |
| `create_lifecycle_policy`            | Create a lifecycle policy                                      | `bool`         | `false`       |
| `repository_lifecycle_policy`        | Lifecycle policy JSON                                          | `string`       | `null`        |
| `tags`                               | Per-repository tags                                            | `map(string)`  | `{}`          |

### Public Repositories

| Name                  | Description                                 | Type                 | Default | Required |
| --------------------- | ------------------------------------------- | -------------------- | ------- | -------- |
| `public_repositories` | Map of public ECR repository configurations | `map(object({...}))` | `{}`    | no       |

Each public repository object supports:

| Key                                 | Description                                                        | Type           | Default |
| ----------------------------------- | ------------------------------------------------------------------ | -------------- | ------- |
| `name`                              | Explicit repository name (overrides the naming convention)         | `string`       | `null`  |
| `catalog_data`                      | Catalog data (about/usage text, description, architectures, OS, logo) | `object`    | `null`  |
| `attach_repository_policy`          | Attach a repository policy                                         | `bool`         | `false` |
| `create_repository_policy`          | Auto-generate repository policy                                    | `bool`         | `true`  |
| `repository_policy`                 | Pre-built policy JSON (when create_repository_policy is false)     | `string`       | `null`  |
| `repository_read_access_arns`       | ARNs with read access (`*` when empty)                             | `list(string)` | `[]`    |
| `repository_read_write_access_arns` | ARNs with read-write access                                        | `list(string)` | `[]`    |
| `repository_policy_statements`      | Custom IAM policy statements                                       | `map(object)`  | `null`  |
| `tags`                              | Per-repository tags                                                | `map(string)`  | `{}`    |

### Registry-Level Features

| Name                                        | Description                               | Type                  | Default      | Required |
| ------------------------------------------- | ----------------------------------------- | --------------------- | ------------ | -------- |
| `create_registry_policy`                    | Create registry-level IAM policy          | `bool`                | `false`      | no       |
| `registry_policy`                           | Registry policy JSON                      | `string`              | `null`       | no       |
| `registry_pull_through_cache_rules`         | Map of pull-through cache rules (`ecr_repository_prefix`, `upstream_registry_url`, optional `credential_arn`, `custom_role_arn`, `upstream_repository_prefix`, `region`) | `map(object({...}))` | `{}` | no |
| `manage_registry_scanning_configuration`    | Manage registry scanning config           | `bool`                | `false`      | no       |
| `registry_scan_type`                        | Scan type: ENHANCED or BASIC              | `string`              | `"ENHANCED"` | no       |
| `registry_scan_rules`                       | Scanning rules with frequency and filters | `list(object({...}))` | `null`       | no       |
| `create_registry_replication_configuration` | Create replication config                 | `bool`                | `false`      | no       |
| `registry_replication_rules`                | Replication rules with destinations (max 10) | `list(object({...}))` | `null`    | no       |

## Outputs

| Name                                | Description                                       |
| ----------------------------------- | ------------------------------------------------- |
| `repository_arns`                   | Map of repository keys to ARNs                    |
| `repository_names`                  | Map of repository keys to names                   |
| `repository_urls`                   | Map of repository keys to URLs                    |
| `repository_registry_ids`           | Map of repository keys to registry IDs            |
| `public_repository_arns`            | Map of public repository keys to ARNs             |
| `public_repository_uris`            | Map of public repository keys to URIs             |
| `public_repository_registry_ids`    | Map of public repository keys to registry IDs     |
| `registry_scanning_configuration`   | The registry scanning configuration               |
| `registry_pull_through_cache_rules` | Map of pull-through cache rules                   |
| `repositories_summary`              | Comprehensive summary of all private repositories |
| `public_repositories_summary`       | Comprehensive summary of all public repositories  |

## Naming Convention

All private repositories follow the naming pattern:

```
{region_prefix}-ecr-{account_name}-{project_name}-{repository_key}
```

**Examples:**

- `ause1-ecr-prod-myapp-api` (us-east-1, prod account, myapp project, api repo)
- `euw1-ecr-dev-platform-worker` (eu-west-1, dev account, platform project, worker repo)

Public repositories use: `{account_name}-{project_name}-{repository_key}` (no region prefix, ECR Public is global).

Any repository name can be overridden with the `name` attribute of its entry. `account_name` and `project_name` must be 1-32 characters of lowercase letters, numbers and hyphens.

## Tags

Every repository gets `merge(tags_common, {RepositoryKey, AccountName, ProjectName, Region, RegionCode}, <repository tags>, {Name, ManagedBy = "Terraform"})`. Public repositories do not get `Region`/`RegionCode`.

## Region Prefix Mapping

| Region         | Prefix | Region         | Prefix |
| -------------- | ------ | -------------- | ------ |
| us-east-1      | ause1  | eu-central-1   | euc1   |
| us-east-2      | ause2  | eu-central-2   | euc2   |
| us-west-1      | ausw1  | eu-west-1      | euw1   |
| us-west-2      | ausw2  | eu-west-2      | euw2   |
| af-south-1     | afs1   | eu-west-3      | euw3   |
| ap-east-1      | ape1   | eu-south-1     | eus1   |
| ap-east-2      | ape2   | eu-south-2     | eus2   |
| ap-south-1     | aps1   | eu-north-1     | eun1   |
| ap-south-2     | aps2   | il-central-1   | ilc1   |
| ap-southeast-1 | apse1  | me-south-1     | mes1   |
| ap-southeast-2 | apse2  | me-central-1   | mec1   |
| ap-southeast-3 | apse3  | sa-east-1      | sae1   |
| ap-southeast-4 | apse4  | ca-central-1   | cac1   |
| ap-southeast-5 | apse5  | ca-west-1      | caw1   |
| ap-southeast-6 | apse6  | mx-central-1   | mxc1   |
| ap-southeast-7 | apse7  | ap-northeast-1 | apne1  |
| ap-northeast-2 | apne2  | ap-northeast-3 | apne3  |

Regions not in the map use the full region name as prefix (e.g. `xx-east-1-ecr-...`). Set `region_prefix` to override it.

## Troubleshooting

### Error: repository_policy must be provided

```
Error: repository_policy must be provided when attach_repository_policy is true and create_repository_policy is false.
```

**Solution**: Either pass a `repository_policy` JSON, set `create_repository_policy = true` or set `attach_repository_policy = false`.

### Error: image_tag_mutability invalid

```
Error: image_tag_mutability must be one of: MUTABLE, IMMUTABLE.
```

**Solution**: Use one of the valid values for `image_tag_mutability`.

### Error: Public repository requires us-east-1

ECR Public repositories can only be created in `us-east-1`. Use a provider configured for that region, or set `region = "us-east-1"` on a module instance dedicated to `public_repositories`.

### Error: Registry scanning already configured

Only one scanning configuration can exist per registry. If you get a conflict, ensure only one module instance manages `manage_registry_scanning_configuration = true`.

## License

MIT Licensed. See [LICENSE](LICENSE) for full details.

## Author

Created and maintained by [Jhon Meza](https://github.com/jhonmezaa).
