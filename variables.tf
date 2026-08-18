# SPDX-License-Identifier: Apache-2.0

# ─── Identity ──────────────────────────────────────────────────────────

variable "organization" {
  type        = string
  description = "Organization slug, used for the Actions policy resources and in error messages. Must match the owner configured on the github provider passed in by the caller."
}

# ─── Profile, required because the resource resets what it omits ───────
#
# github_organization_settings manages the entire settings object. A field left
# unset is written as empty, not skipped, so omitting one wipes it from the org
# profile. None of these have defaults: a caller must state the current values,
# which also makes the first apply a verifiable no-op.

variable "billing_email" {
  type        = string
  description = "Billing address for the organization. Required by the provider, and there is no safe default: a wrong value is written to the org."
}

variable "name" {
  type        = string
  description = "Display name of the organization. Stated explicitly because an omitted value is cleared, not left alone."
}

variable "description" {
  type        = string
  description = "Organization description. Stated explicitly because an omitted value is cleared, not left alone."
}

variable "blog" {
  type        = string
  description = "Organization URL. Stated explicitly because an omitted value is cleared, not left alone."
  default     = ""
}

variable "location" {
  type        = string
  description = "Organization location. Stated explicitly because an omitted value is cleared, not left alone."
  default     = ""
}

variable "email" {
  type        = string
  description = "Public contact address on the organization profile. Distinct from billing_email."
  default     = ""
}

variable "company" {
  type        = string
  description = "Company field on the organization profile."
  default     = ""
}

variable "twitter_username" {
  type        = string
  description = "Twitter handle on the organization profile."
  default     = ""
}

# ─── Member permissions ────────────────────────────────────────────────

variable "default_repository_permission" {
  type        = string
  description = "Permission every member gets on every repository: none, read, write or admin. read is the hardened choice, since write should be granted deliberately rather than inherited."
  default     = "read"

  validation {
    condition     = contains(["none", "read", "write", "admin"], var.default_repository_permission)
    error_message = "default_repository_permission must be one of: none, read, write, admin."
  }
}

variable "members_can_create_repositories" {
  type        = bool
  description = "Allow members to create repositories at all. Defaults false: repository creation is an owner decision, and an unmanaged repository is one nothing governs."
  default     = false
}

variable "members_can_create_public_repositories" {
  type        = bool
  description = "Allow members to create PUBLIC repositories. Defaults false, and this is the single highest-value setting in this module: it is the difference between a private-by-default organization and one where any member can publish source with one click."
  default     = false
}

variable "members_can_create_private_repositories" {
  type        = bool
  description = "Allow members to create private repositories."
  default     = false
}

variable "members_can_create_internal_repositories" {
  type        = bool
  description = "Allow members to create internal repositories. Enterprise-only concept; harmless to leave false elsewhere."
  default     = false
}

variable "members_can_create_pages" {
  type        = bool
  description = "Allow members to publish GitHub Pages sites."
  default     = false
}

variable "members_can_create_public_pages" {
  type        = bool
  description = "Allow members to publish PUBLIC Pages sites, which serve organization content on the open internet."
  default     = false
}

variable "members_can_create_private_pages" {
  type        = bool
  description = "Allow members to publish private Pages sites."
  default     = false
}

variable "members_can_fork_private_repositories" {
  type        = bool
  description = "Allow members to fork private repositories into personal namespaces. Defaults false: a fork moves private source somewhere the organization's rulesets and scanning do not reach."
  default     = false
}

variable "web_commit_signoff_required" {
  type        = bool
  description = "Require a sign-off on commits made through the GitHub web UI. Defaults true: the web editor bypasses local hooks, so without this it is the one path that can land an unsigned-off commit in a repo that otherwise enforces DCO."
  default     = true
}

variable "has_organization_projects" {
  type        = bool
  description = "Enable organization-level projects."
  default     = true
}

variable "has_repository_projects" {
  type        = bool
  description = "Enable repository-level projects."
  default     = true
}

# ─── Advanced Security capability axis ─────────────────────────────────

variable "has_advanced_security" {
  type        = bool
  description = <<-EOT
    Whether this organization can actually use GitHub Advanced Security.

    Defaults false, which forces every GHAS-dependent setting below off
    regardless of its own value. Secret scanning, push protection, Dependabot
    alerts and the dependency graph are free on public repositories but need a
    paid plan for private ones, and requesting them on a free organization is
    rejected rather than ignored.

    Set true only if the organization is genuinely on a plan that includes them.
    The individual variables can still turn a feature off while this is true,
    but cannot turn one on while it is false.
  EOT
  default     = false
}

variable "advanced_security_enabled_for_new_repositories" {
  type        = bool
  description = "Enable Advanced Security on newly created repositories. Gated by has_advanced_security."
  default     = false
}

variable "secret_scanning_enabled_for_new_repositories" {
  type        = bool
  description = "Enable secret scanning on newly created repositories. Gated by has_advanced_security."
  default     = false
}

variable "secret_scanning_push_protection_enabled_for_new_repositories" {
  type        = bool
  description = "Enable secret-scanning push protection on newly created repositories, which blocks a secret at push time rather than reporting it afterwards. Gated by has_advanced_security."
  default     = false
}

variable "dependabot_alerts_enabled_for_new_repositories" {
  type        = bool
  description = "Enable Dependabot alerts on newly created repositories. Alerts only notify; they do not open pull requests. Gated by has_advanced_security."
  default     = false
}

variable "dependency_graph_enabled_for_new_repositories" {
  type        = bool
  description = "Enable the dependency graph on newly created repositories. Alerts depend on it. Gated by has_advanced_security."
  default     = false
}

variable "dependabot_security_updates_enabled_for_new_repositories" {
  type        = bool
  description = "Enable Dependabot security updates on newly created repositories. Unlike alerts, this opens pull requests, so leave it false where bot pull requests are unwanted. Gated by has_advanced_security."
  default     = false
}

# ─── Actions policy ────────────────────────────────────────────────────

variable "manage_actions_workflow_permissions" {
  type        = bool
  description = "Manage the organization default for the GITHUB_TOKEN permission and for whether Actions may approve pull requests."
  default     = true
}

variable "default_workflow_permissions" {
  type        = string
  description = "Default GITHUB_TOKEN permission for workflows in the organization: read or write. read is the hardened choice, so a workflow that needs to push has to say so."
  default     = "read"

  validation {
    condition     = contains(["read", "write"], var.default_workflow_permissions)
    error_message = "default_workflow_permissions must be read or write."
  }
}

variable "can_approve_pull_request_reviews" {
  type        = bool
  description = "Allow GitHub Actions to approve pull requests. Defaults false: letting a workflow approve a change defeats required review, because the change can approve itself."
  default     = false
}

variable "manage_actions_permissions" {
  type        = bool
  description = "Manage which repositories may run Actions and which actions they may use. Defaults false, because the allowed-actions policy is the setting most likely to break an existing pipeline, so it should be adopted deliberately."
  default     = false
}

variable "actions_enabled_repositories" {
  type        = string
  description = "Which repositories may run Actions: all, none or selected."
  default     = "all"

  validation {
    condition     = contains(["all", "none", "selected"], var.actions_enabled_repositories)
    error_message = "actions_enabled_repositories must be one of: all, none, selected."
  }
}

variable "allowed_actions" {
  type        = string
  description = "Which actions may run: all, local_only or selected. selected is the hardened choice and enables the allowed_actions_* inputs below."
  default     = "selected"

  validation {
    condition     = contains(["all", "local_only", "selected"], var.allowed_actions)
    error_message = "allowed_actions must be one of: all, local_only, selected."
  }
}

variable "allowed_actions_github_owned" {
  type        = bool
  description = "Allow actions published by GitHub itself, such as actions/checkout. Only applies when allowed_actions is selected."
  default     = true
}

variable "allowed_actions_verified" {
  type        = bool
  description = "Allow actions from verified Marketplace creators. Only applies when allowed_actions is selected."
  default     = false
}

variable "allowed_actions_patterns" {
  type        = list(string)
  description = "Explicit action patterns to allow, for example [\"my-org/*\"]. Only applies when allowed_actions is selected. Prefer naming the actions you rely on over allowing a whole marketplace tier."
  default     = []
}
