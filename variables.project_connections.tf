variable "project_connections" {
  type = map(object({
    project_name = string
    name         = string
    audience     = string
    target       = string
    models = map(object({
      model_name    = string
      model_version = optional(string, "")
    }))
  }))
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION.

APIM connections keyed by caller-selected keys, created in existing projects in this account. Defaults to no connections. This does not create or adopt projects, gateways, routes, identities or authorization.

- `project_name` - Name of an existing project in this account. For projects created by another module in the same graph, source `modules/project-connection` directly with the project's ARM ID to avoid a dependency cycle.
- `name` - Project connection name.
- `audience` - Entra token resource URI, not a JWT audience GUID or `/.default` scope.
- `target` - HTTPS Chat Completions base URL.
- `models` - Static catalog keyed by gateway deployment alias; each value contains `model_name` and optional `model_version` (default empty string). Agents explicitly select `connectionName/alias`. Catalog configuration does not publish or verify routes.
DESCRIPTION

  validation {
    condition     = length(var.project_connections) == 0 || var.kind == "AIServices"
    error_message = "Project connections require an AIServices account."
  }

  validation {
    condition     = alltrue([for connection in var.project_connections : can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{1,63}$", connection.project_name))])
    error_message = "Each project_name must be 2-64 alphanumeric, dot, underscore or hyphen characters, starting with an alphanumeric character."
  }
}

variable "resource_types" {
  type = object({
    cognitiveservices_accounts                        = optional(string, "Microsoft.CognitiveServices/accounts@2025-06-01")
    network_private_endpoints                         = optional(string, "Microsoft.Network/privateEndpoints@2024-05-01")
    network_private_endpoints_private_dns_zone_groups = optional(string, "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01")
    authorization_role_assignments                    = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    authorization_locks                               = optional(string, "Microsoft.Authorization/locks@2020-05-01")

    cognitiveservices_accounts_projects_connections = optional(object({
      cognitiveservices_accounts_projects_connections = optional(string)
    }), {})
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
AzAPI overrides for owned resources and project-connection submodules. Existing API-version defaults are unchanged. Deployment and RAI-policy APIs retain their existing configuration.

- `cognitiveservices_accounts` - Account resource and HSM encryption updater type/API version.
- `network_private_endpoints` - Private endpoints and their existing-resource lookup.
- `network_private_endpoints_private_dns_zone_groups` - Private endpoint DNS zone groups.
- `authorization_role_assignments` - Existing private endpoint role assignments.
- `authorization_locks` - Existing private endpoint locks.
- `cognitiveservices_accounts_projects_connections` - Overrides passed unchanged to each connection child.
- `cognitiveservices_accounts_projects_connections.cognitiveservices_accounts_projects_connections` - Connection resource type/API version override; the child owns the default.
DESCRIPTION
}

variable "ignore_body_changes" {
  type = object({
    cognitiveservices_accounts                        = optional(list(string), [])
    network_private_endpoints                         = optional(list(string), [])
    network_private_endpoints_private_dns_zone_groups = optional(list(string), [])
    authorization_role_assignments                    = optional(list(string), [])
    authorization_locks                               = optional(list(string), [])

    cognitiveservices_accounts_projects_connections = optional(object({
      cognitiveservices_accounts_projects_connections = optional(list(string), [])
    }), {})
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Body-relative dot paths ignored on owned resources and project connections. Ignored configuration is not sent to Azure; changes take effect only after apply. Defaults preserve existing behavior and all static lifecycle ignores. Deployment and RAI-policy ignores retain their existing configuration.

- `cognitiveservices_accounts` - Primary account body paths. Defaults to `[]` (no additional ignores). The HSM updater does not support this provider argument and retains its existing static lifecycle ignore.
- `network_private_endpoints` - Private endpoint body paths, for both DNS management variants.
- `network_private_endpoints_private_dns_zone_groups` - Private endpoint DNS zone group body paths.
- `authorization_role_assignments` - Existing private endpoint role assignment body paths.
- `authorization_locks` - Existing private endpoint lock body paths.
- `cognitiveservices_accounts_projects_connections` - Paths passed unchanged to each connection child.
- `cognitiveservices_accounts_projects_connections.cognitiveservices_accounts_projects_connections` - Connection body paths; ignore whole lists, not individual indices.
DESCRIPTION
}
