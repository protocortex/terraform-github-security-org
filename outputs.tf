# SPDX-License-Identifier: Apache-2.0

output "organization" {
  description = "Slug of the organization this module hardened."
  value       = var.organization
}

output "default_repository_permission" {
  description = "Effective baseline permission every member holds on every repository."
  value       = github_organization_settings.this.default_repository_permission
}

output "members_can_create_public_repositories" {
  description = "Whether members may publish public repositories. False is the hardened state."
  value       = github_organization_settings.this.members_can_create_public_repositories
}

output "advanced_security_active" {
  description = "Whether the Advanced Security capability gate is open. False means every GHAS-dependent setting was forced off regardless of its own value."
  value       = local._ghas
}

output "actions_workflow_permissions_id" {
  description = "Id of the Actions workflow-permissions resource, or null when unmanaged."
  value       = try(github_actions_organization_workflow_permissions.this[0].id, null)
}

output "actions_permissions_id" {
  description = "Id of the Actions permissions policy, or null when unmanaged."
  value       = try(github_actions_organization_permissions.this[0].id, null)
}
