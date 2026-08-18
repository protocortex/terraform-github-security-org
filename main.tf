# SPDX-License-Identifier: Apache-2.0
#
# Module: github-security-org
#
# Org-level hardening: the settings that sit above every repository and decide
# what a new one inherits. The sibling module terraform-github-security-repo
# hardens repositories one at a time; this one sets the floor they land on.
#
# Safety: github_organization_settings is an all-or-nothing resource. It manages
# the whole settings object, so any optional field left unset reverts, including
# the org's public profile. Every such field is therefore a required input here
# rather than an optional one with a default. See variables.tf.

# ─── Effective variable resolution ─────────────────────────────────────
#
# One capability axis. GitHub Advanced Security, and the per-repo secret
# scanning and Dependabot alert defaults that depend on it, are only available
# on paid plans or public repositories. Requesting them on a free org returns an
# error, so they are gated behind a single flag rather than eight separate ones.
#
# Resources below read local.eff_* instead of var.* for anything gated.

locals {
  # Capability gate. Defaults closed: a free org is the common case, and the
  # failure mode of guessing wrong is a hard error at apply rather than a
  # silently weaker posture.
  _ghas = var.has_advanced_security

  eff_advanced_security               = local._ghas ? var.advanced_security_enabled_for_new_repositories : false
  eff_secret_scanning                 = local._ghas ? var.secret_scanning_enabled_for_new_repositories : false
  eff_secret_scanning_push_protection = local._ghas ? var.secret_scanning_push_protection_enabled_for_new_repositories : false
  eff_dependabot_alerts               = local._ghas ? var.dependabot_alerts_enabled_for_new_repositories : false
  eff_dependency_graph                = local._ghas ? var.dependency_graph_enabled_for_new_repositories : false
  eff_dependabot_security_updates     = local._ghas ? var.dependabot_security_updates_enabled_for_new_repositories : false
}

check "advanced_security_requires_capability" {
  assert {
    condition = (
      var.has_advanced_security
      || !(
        var.advanced_security_enabled_for_new_repositories
        || var.secret_scanning_enabled_for_new_repositories
        || var.secret_scanning_push_protection_enabled_for_new_repositories
        || var.dependabot_alerts_enabled_for_new_repositories
        || var.dependency_graph_enabled_for_new_repositories
        || var.dependabot_security_updates_enabled_for_new_repositories
      )
    )
    error_message = "Org ${var.organization} requests an Advanced Security feature for new repositories while has_advanced_security is false, so the gate forces it off. These settings need a paid plan or public repositories; on a free org GitHub rejects them. Either set has_advanced_security = true if the org really is on a plan that includes them, or set the individual feature variables to false to make the intent explicit."
  }
}

check "profile_is_stated" {
  assert {
    condition     = trimspace(var.billing_email) != ""
    error_message = "Org ${var.organization} has an empty billing_email. github_organization_settings manages the whole settings object, so a blank value here is written to the org rather than ignored. Pass the address the org actually bills to."
  }
}

# ─── Org settings ──────────────────────────────────────────────────────
#
# Every field the provider supports is set explicitly. That is deliberate and
# not verbosity: anything omitted is reset, so an omission silently wipes the
# org profile or relaxes a control. The profile fields carry no defaults in
# variables.tf so a caller cannot forget them by accident.

resource "github_organization_settings" "this" {
  billing_email = var.billing_email

  # Profile. Managed only because the resource resets what it does not manage,
  # not because this module wants to own branding.
  name             = var.name
  description      = var.description
  company          = var.company
  blog             = var.blog
  email            = var.email
  location         = var.location
  twitter_username = var.twitter_username

  # Baseline member permissions. read means a new member sees repositories but
  # cannot push without being granted more.
  default_repository_permission = var.default_repository_permission

  # Repository creation. Public creation is the one that matters most: it is the
  # difference between a private-by-default org and one where any member can
  # publish source with a single click.
  members_can_create_repositories          = var.members_can_create_repositories
  members_can_create_public_repositories   = var.members_can_create_public_repositories
  members_can_create_private_repositories  = var.members_can_create_private_repositories
  members_can_create_internal_repositories = var.members_can_create_internal_repositories
  members_can_create_pages                 = var.members_can_create_pages
  members_can_create_public_pages          = var.members_can_create_public_pages
  members_can_create_private_pages         = var.members_can_create_private_pages

  # Forking private repositories moves private source into personal namespaces
  # that the org cannot govern.
  members_can_fork_private_repositories = var.members_can_fork_private_repositories

  # Requires a sign-off on commits made through the GitHub web UI, which
  # otherwise bypasses any local hook or DCO check.
  web_commit_signoff_required = var.web_commit_signoff_required

  has_organization_projects = var.has_organization_projects
  has_repository_projects   = var.has_repository_projects

  # Security defaults inherited by newly created repositories. All gated: see
  # the capability axis above.
  advanced_security_enabled_for_new_repositories               = local.eff_advanced_security
  secret_scanning_enabled_for_new_repositories                 = local.eff_secret_scanning
  secret_scanning_push_protection_enabled_for_new_repositories = local.eff_secret_scanning_push_protection
  dependabot_alerts_enabled_for_new_repositories               = local.eff_dependabot_alerts
  dependency_graph_enabled_for_new_repositories                = local.eff_dependency_graph
  dependabot_security_updates_enabled_for_new_repositories     = local.eff_dependabot_security_updates
}

# ─── Actions policy ────────────────────────────────────────────────────
#
# These are the defaults a repository inherits, so they matter most for repos
# that do not exist yet. A repo-level override still wins.

resource "github_actions_organization_workflow_permissions" "this" {
  count = var.manage_actions_workflow_permissions ? 1 : 0

  organization_slug = var.organization

  # A read-only default token means a compromised or careless workflow cannot
  # push, tag or open a release without the repository opting back in.
  default_workflow_permissions = var.default_workflow_permissions

  # Letting Actions approve pull requests defeats required review: a workflow
  # could approve its own change.
  can_approve_pull_request_reviews = var.can_approve_pull_request_reviews
}

resource "github_actions_organization_permissions" "this" {
  count = var.manage_actions_permissions ? 1 : 0

  enabled_repositories = var.actions_enabled_repositories
  allowed_actions      = var.allowed_actions

  # Only meaningful when allowed_actions is "selected"; an empty block would be
  # rejected, so it is present only in that case.
  dynamic "allowed_actions_config" {
    for_each = var.allowed_actions == "selected" ? [1] : []

    content {
      github_owned_allowed = var.allowed_actions_github_owned
      verified_allowed     = var.allowed_actions_verified
      patterns_allowed     = var.allowed_actions_patterns
    }
  }
}
