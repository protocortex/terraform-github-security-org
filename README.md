<!-- SPDX-License-Identifier: Apache-2.0 -->
# terraform-github-security-org

Reusable OpenTofu/Terraform module that hardens a GitHub **organization**: member
permissions, who may create repositories, the security defaults a new repository inherits,
and the organization-wide Actions policy. Works with the `integrations/github` **v6**
provider.

Companion to [`terraform-github-security-repo`](https://github.com/protocortex/terraform-github-security-repo),
which hardens repositories one at a time. This module sets the floor they land on, so it
matters most for repositories that do not exist yet.

Pin it by tag.

## Usage

```hcl
provider "github" {
  owner = "my-org"
  # App or token needs Organization administration: write
}

module "org_hardening" {
  source = "git::https://github.com/protocortex/terraform-github-security-org.git?ref=v0.1.0"

  organization = "my-org"

  # Required, and deliberately without defaults: the underlying resource manages
  # the whole settings object, so anything omitted is CLEARED from the profile.
  billing_email = "billing@example.com"
  name          = "My Org"
  description   = "What this org does"
  blog          = "https://example.com/"
  location      = "Somewhere"

  # Defaults are already the hardened choice; shown for clarity.
  members_can_create_public_repositories = false
  members_can_fork_private_repositories  = false
  web_commit_signoff_required            = true

  # Leave false on a free org: turning it on does not enable the features, it
  # makes the apply fail.
  has_advanced_security = false
}
```

The **provider is configured by the caller**, not the module.

## Adopt it with a no-op first

`github_organization_settings` manages the **entire** settings object. A field left unset is
written as empty rather than skipped, so a forgotten input wipes it from the organization
profile.

Read the current values first and pass them verbatim, so the first plan reports **no
changes at all**. Only then tighten, in a second commit, so the diff is small and
reviewable:

```
gh api /orgs/<org> --jq '{billing_email,name,description,blog,location}'
```

## What it manages (all free tier unless noted)

| Resource | Purpose |
|---|---|
| `github_organization_settings` | Baseline member permission, repository- and Pages-creation rules, private-fork policy, web commit sign-off, and the security defaults new repositories inherit |
| `github_actions_organization_workflow_permissions` | Default `GITHUB_TOKEN` permission and whether Actions may approve pull requests |
| `github_actions_organization_permissions` | Which repositories may run Actions and which actions they may use |

## Not covered: two-factor enforcement

Requiring 2FA for all members **cannot be managed here**. The setting does not exist on
`github_organization_settings` in the v6 provider, so there is nothing to write. It remains
a dashboard action, under Settings, Authentication security. Stated plainly because a
module called "security-org" would otherwise be assumed to cover it.

## Key inputs

| Name | Default | Description |
|---|---|---|
| `organization` | _required_ | Org slug; must match the provider's `owner` |
| `billing_email` | _required_ | Billing address; no safe default, a wrong value is written to the org |
| `name`, `description` | _required_ | Profile fields; omitted means cleared |
| `blog`, `location`, `email`, `company`, `twitter_username` | `""` | Remaining profile fields |
| `default_repository_permission` | `read` | Baseline permission every member holds |
| `members_can_create_public_repositories` | `false` | The highest-value setting here: private-by-default versus anyone can publish |
| `members_can_create_repositories` | `false` | Repository creation as an owner decision |
| `members_can_fork_private_repositories` | `false` | Forking moves private source outside the org's reach |
| `web_commit_signoff_required` | `true` | Closes the web-editor path that bypasses local hooks and DCO |
| `has_advanced_security` | `false` | Capability gate; forces every GHAS-dependent setting off while closed |
| `manage_actions_workflow_permissions` | `true` | Manage the token default and PR-approval setting |
| `default_workflow_permissions` | `read` | Default `GITHUB_TOKEN` permission |
| `can_approve_pull_request_reviews` | `false` | Actions approving PRs defeats required review |
| `manage_actions_permissions` | `false` | Off by default: the allowed-actions policy is the setting most likely to break an existing pipeline |
| `allowed_actions` | `selected` | Applies only when `manage_actions_permissions` is true |

## Outputs

`organization`, `default_repository_permission`, `members_can_create_public_repositories`,
`advanced_security_active` (false means the gate forced every GHAS setting off),
`actions_workflow_permissions_id` and `actions_permissions_id` (null when unmanaged).

## License

Apache-2.0. See [LICENSE](LICENSE).
