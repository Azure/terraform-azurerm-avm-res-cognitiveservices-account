# Foundry project APIM connection

Creates one project-scoped connected-model connection to an **existing** Azure
API Management gateway. The caller owns cardinality. No account, project, APIM
resources, API keys, policies, RBAC or app-role grants are created or read.

Uses `ApiManagement`, `ProjectManagedIdentity`, empty credentials and
`isSharedToAll = false`, with static OpenAI model metadata and body-based model
selection (`deploymentInPath = "false"`). The
[Microsoft sample](https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/01-connections/apim/modules/apim-connection-common.bicep)
uses preview category/authentication fields absent from the
[published ARM schema](https://learn.microsoft.com/azure/templates/microsoft.cognitiveservices/2025-04-01-preview/accounts/projects/connections).
Schema validation is disabled only on this connection resource. Azure acceptance
and persistence still require real deployment/readback.

The existing project must have an identity authorized by the gateway owner.
Configure project/account identities through their owning modules; attaching an
identity does not prove which runtime token is used. This contract has no explicit
per-connection UAMI selector. Verify the caller's client/principal and audience in
gateway logs before activation, without broadening access to compensate.

The target is an HTTPS Chat Completions **base** URL, and the audience is the Entra
token resource URI, not a `/.default` scope. Static models follow the
[documented deployment/model shape](https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/01-connections/apim/APIM-Connection-Objects.md).
Agents must explicitly select `connectionName/gatewayDeploymentName`. This is not
an account-level AI Gateway association and does not redirect other model calls.

No discovery, deployment paths, inference/deployment API versions, custom headers
or Responses routing are configured. Verify the actual route, query, model body,
DNS/TLS/network access, token validation, gateway readiness, backend access and
request/response contract separately. Persistence and portal model visibility do
not prove successful inference.

## Composition

Source this submodule directly when another module owns or creates the project;
pass that project's ARM ID as `parent_id`. This avoids a dependency cycle between
an account, a separately managed project, and its connection. The account module's
`project_connections` interface is for projects that already exist in that account.
Neither interface adopts or changes project ownership.

For a local checkout, a direct call is:

```hcl
module "gateway_connection" {
  source = "./modules/project-connection"

  name             = "enterprise-models"
  parent_id        = var.existing_project_resource_id
  target           = "https://gateway.example.com/ai/v1"
  audience         = "api://gateway"
  enable_telemetry = false
  models = {
    chat = { model_name = "gpt-4.1", model_version = "2025-04-14" }
  }
}
```

For Registry consumption, select an actual released version containing this
submodule; v0.12.0 does not contain it. Do not treat this local example as a
released dependency.

There are no released resource-module connection addresses to migrate from
v0.12.0. Existing account, deployment and RAI-policy addresses are unchanged.
Adopting an already managed connection requires a separately reviewed state
handoff; do not configure two owners for the same connection.
