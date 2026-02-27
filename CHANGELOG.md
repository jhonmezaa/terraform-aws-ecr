# Changelog

## [v1.1.0] - 2026-02-27

### Added
- `use_region_prefix` boolean variable (default: `true`) to control whether the region prefix is included in resource names. When `false`, names omit the prefix


## [v1.0.3] - 2026-02-27

### Fixed
- Remove unsupported `image_tag_mutability_exclusion_filter` dynamic block not available in current stable AWS provider
- Remove `MUTABLE_WITH_EXCLUSION` and `IMMUTABLE_WITH_EXCLUSION` from `image_tag_mutability` validation


## [v1.0.2] - 2026-02-27

### Changed
- Standardize Terraform `required_version` to `~> 1.0` across module and examples


## [v1.0.1] - 2026-02-27

### Changed
- Update AWS provider constraint to `~> 6.0` across module and examples


All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-09

### Added

#### Private ECR Repositories
- **Multiple repository creation** via `for_each` on `repositories` map variable
- **Image tag mutability** with 4 modes: `MUTABLE`, `IMMUTABLE`, `MUTABLE_WITH_EXCLUSION`, `IMMUTABLE_WITH_EXCLUSION`
- **Image tag mutability exclusion filters** for WILDCARD pattern matching
- **Encryption configuration**: AES256 (default) or KMS with custom key ARN
- **Image scanning on push** (enabled by default)
- **Force delete** capability for repositories with images
- **Automatic naming convention**: `{region_prefix}-ecr-{account_name}-{project_name}-{key}`

#### Repository Policies (IAM)
- **Auto-generated policy** using `aws_iam_policy_document` with dynamic statements:
  - `PrivateReadOnly`: Read access for specified ARNs (falls back to account root)
  - `PrivateLambdaReadOnly`: Lambda service principal access with `aws:sourceArn` condition
  - `ReadWrite`: Push/upload access for specified ARNs
  - Custom statements with full IAM policy support (principals, conditions, etc.)
- **Pre-built policy** option via JSON string
- **Separate control** for policy creation (`create_repository_policy`) vs attachment (`attach_repository_policy`)

#### Lifecycle Policies
- **Per-repository lifecycle policies** for image retention management
- Support for tagged/untagged image expiration rules
- JSON policy document format

#### Public ECR Repositories
- **Multiple public repository creation** via `for_each` on `public_repositories` map
- **Catalog data** support: about_text, architectures, description, logo, operating_systems, usage_text
- **Public repository policies** with `ecr-public:*` actions
- Separate naming convention (no region prefix, ECR Public is global)

#### Registry Scanning Configuration
- **Scan type**: `ENHANCED` (default) or `BASIC`
- **Multiple scan rules** with configurable frequency:
  - `SCAN_ON_PUSH`: Scan on every image push
  - `CONTINUOUS_SCAN`: Continuous vulnerability scanning
- **Repository filters** with WILDCARD pattern matching

#### Registry Replication Configuration
- **Cross-region replication** with multiple destination support
- **Cross-account replication** via registry ID
- **Repository filters** with `PREFIX_MATCH` filtering
- Support for up to 10 replication rules

#### Pull-Through Cache Rules
- **Multiple upstream registries** via `for_each` on map variable
- Support for:
  - Docker Hub (`registry-1.docker.io`)
  - GitHub Container Registry (`ghcr.io`)
  - ECR Public (`public.ecr.aws`)
  - Other OCI-compliant registries
- **Credential support** for authenticated upstream registries
- **Custom IAM role** support for cache operations

#### Registry Policy
- **Registry-level IAM policy** for replication and pull-through cache permissions
- JSON formatted policy document

#### Module Organization
- **Standardized file structure** following monorepo conventions:
  - `0-versions.tf` - Terraform and provider version constraints
  - `1-repository.tf` - Private ECR repositories
  - `2-repository-policy.tf` - Repository IAM policies
  - `3-lifecycle-policy.tf` - Image lifecycle policies
  - `4-public-repository.tf` - Public ECR repositories
  - `5-registry-scanning.tf` - Registry scanning configuration
  - `6-registry-replication.tf` - Cross-region replication
  - `7-pull-through-cache.tf` - Pull-through cache rules
  - `8-registry-policy.tf` - Registry-level IAM policy
  - `9-locals.tf` - Local values and naming logic
  - `10-data.tf` - Data sources
  - `11-variables.tf` - Input variables
  - `12-outputs.tf` - Output values

#### Naming Convention
- Automatic naming: `{region_prefix}-ecr-{account_name}-{project_name}-{key}`
- Auto-detection of AWS region from provider configuration
- Region code mapping for 29 AWS regions
- Centralized tagging with `tags_common` variable

#### Examples
- `examples/basic/` - Basic multi-repository deployment
- `examples/complete/` - Full-featured deployment with all features

#### Documentation
- Complete `README.md` with usage examples
- Input/Output reference tables
- Troubleshooting guide
- Architecture patterns

### Technical Requirements
- **Terraform**: >= 1.5.7
- **AWS Provider**: >= 5.0

---

[1.0.0]: https://github.com/jhonmezaa/terraform-aws-ecr/releases/tag/v1.0.0
