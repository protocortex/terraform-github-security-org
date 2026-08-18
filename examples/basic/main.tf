# SPDX-License-Identifier: Apache-2.0

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}

# Configured by the caller. Needs an App or token with Organization
# administration write, which is a separate permission from the repository-level
# Administration one.
provider "github" {
  owner = var.organization
}

variable "organization" {
  type = string
}

module "org_hardening" {
  source = "../.."

  organization = var.organization

  # Stated, not defaulted: the underlying resource manages the whole settings
  # object, so anything omitted is cleared from the organization profile. Copy
  # the current live values on first adoption so the first apply is a no-op.
  billing_email = "billing@example.com"
  name          = "Example Org"
  description   = "What this organization does"
  blog          = "https://example.com/"
  location      = "Somewhere"

  # The defaults are already the hardened choice, so most callers set nothing
  # here. Shown for clarity.
  default_repository_permission          = "read"
  members_can_create_public_repositories = false
  members_can_fork_private_repositories  = false
  web_commit_signoff_required            = true

  # Leave false on a free organization. Turning it on there does not enable the
  # features, it makes the apply fail.
  has_advanced_security = false
}

output "advanced_security_active" {
  value = module.org_hardening.advanced_security_active
}
