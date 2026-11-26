# Foundry project connection

Creates one project-scoped connection to an **existing** service. The caller
owns cardinality. No account, project, target service, policies, RBAC or app-role
grants are created or read.

Defaults remain `category = "ApiManagement"`, `auth_type = "ProjectManagedIdentity"`,
empty credentials and `isSharedToAll = false`, with static model metadata and
body-based model selection (`deploymentInPath = "false"`). Each model's
`model_format` defaults to `OpenAI` and can be overridden.

## Categories and body selection

The [ARM reference for the configured API version](https://learn.microsoft.com/azure/templates/microsoft.cognitiveservices/2025-04-01-preview/accounts/projects/connections)
and [Project Connections Create REST API](https://learn.microsoft.com/rest/api/microsoftfoundry/accountmanagement/project-connections/create?view=rest-microsoftfoundry-accountmanagement-2025-06-01)
define a common connection body with an **authType-discriminated** credential
union. Category alone does not select authentication. Locals compose the common
properties, category-specific properties and authentication properties into a
body map selected by `category`.

Any nonblank case-sensitive category is accepted. Known categories at authoring
time come from the `2025-04-01-preview` ARM schema and the Foundry
`ApiManagement` and `AzureStorageAccount` extensions. They include AI services
(`AzureOpenAI`, `AIServices`, `OpenAI`, `CognitiveSearch`, `CognitiveService`,
`BingLLMSearch`, `Serverless`, `ManagedOnlineEndpoint`), storage (`AzureBlob`,
`ADLSGen2`, `AzureOneLake`, `S3`), databases (`CosmosDb`, `AzureSqlDb`, `Snowflake`),
developer services (`Git`, `PythonFeed`, `ContainerRegistry`), and generic
`ApiKey`, `CustomKeys`, `GenericHttp` and `GenericRest` connections. The ARM
reference linked above contains the complete category enumeration.

| Category | Body additions | Required caller inputs |
| --- | --- | --- |
| `ApiManagement` | `audience`, JSON-string `metadata.models`, `metadata.deploymentInPath = "false"` | Audience resource URI and nonempty `models` catalog; HTTPS Chat Completions base target |
| `AzureStorageAccount`, `CosmosDb`, `CognitiveSearch` | Default `metadata.ApiType = "Azure"`, merged with caller metadata | Explicit authentication, service endpoint, service metadata as appropriate; no APIM catalog |
| Other categories, including values not in the authoring-time schema | Nonsecret `metadata` string map; no APIM audience or catalog | Service-specific target, service-supported `auth_type`, service-specific metadata and credentials when applicable |

`audience` and `models` must be omitted for non-APIM categories. APIM reserves
the `models` and `deploymentInPath` metadata keys; other metadata is merged.
Targets for other categories are not forced to use the APIM URL shape: for
example, a Git URL, container registry or service-region target has a different
contract.

### Foundry pattern compatibility

The [Foundry pattern's existing project connections](https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-ai-foundry/blob/598030e13fe3e170476a2804e992f89b7db3fc95/modules/ai-foundry-project/main.tf)
create these non-APIM bodies, which are covered by payload regression tests:

| Category | Authentication | Target shape | Caller metadata |
| --- | --- | --- | --- |
| `AzureStorageAccount` | `AAD` | `https://<account>.blob.core.windows.net/` | `ResourceId`, `location` |
| `CosmosDb` | `AAD` | `https://<account>.documents.azure.com:443/` | `ResourceId`, `location` |
| `CognitiveSearch` | `AAD` | `https://<service>.search.windows.net` | `ResourceId`, `location`, `ApiVersion` (the pattern uses `2024-05-01-preview`) |

These profiles default `ApiType` to `Azure`. The supplied `ResourceId` is
validated against the category's backing resource type. The pattern always emits
the listed metadata; that is evidence of its contract, not proof that every field
is mandatory for all ARM consumers. Metadata and endpoint values are accepted
from the caller rather than derived from resource names, so callers can use
Azure-returned endpoints for their cloud.

The pattern's bodies omit sharing and credentials. This child preserves that
omission for non-APIM categories; it does not equate omission with `false`.
`is_shared_to_all = null` explicitly sends `false` only for APIM. Set the input
to a boolean to override this behavior. The child does not attach project
identities, create connection RBAC grants, impose the pattern's connection
ordering, or create a capability host. Those remain composition responsibilities.
Capability hosts can consume the child's `name` output.

`AzureStorageAccount` is deliberately not rewritten as `AzureBlob`: the
pattern's category is a distinct Foundry service extension missing from the
published ARM enumeration. Key Vault is only a TODO in that implementation;
it is not treated as an implemented connection category here.

The [Foundry connection guidance](https://learn.microsoft.com/azure/foundry/how-to/connections-add)
describes the services exposed in the portal and their runtime limitations.
Those are not identical to the ARM category enumeration or the data-plane
connection types. Newer category names are passed through unchanged using the
common body and caller metadata; no service-specific properties are guessed.
Changing `resource_types` does not automatically add new body variants.
Service-specific metadata, authentication compatibility, permissions
and runtime behavior must be checked for the destination service; accepting an
ARM category does not certify every category/authentication combination.

APIM's preview category/authentication discriminators and Foundry's
`AzureStorageAccount` category remain absent from the published ARM schema.
Schema validation is disabled for categories outside the authoring-time
`2025-04-01-preview` ARM enumeration or when
`auth_type = "ProjectManagedIdentity"`; it remains enabled for documented
category/authentication combinations, including `CosmosDb` and `CognitiveSearch`
with `AAD`. The API-version default and
existing APIM payload are unchanged. Azure acceptance and persistence of newly
configured variants still require real deployment/readback.

## Authentication and credentials

`auth_type` can be overridden independently of `category`. The supported shapes
are:

At authoring time, only `ApiManagement` is known to support
`ProjectManagedIdentity`. The module accepts it for other categories to avoid
blocking future service support; verify acceptance and runtime behavior for the
selected service and API version.

| Authentication | `credentials` entries |
| --- | --- |
| `ProjectManagedIdentity` (APIM preview default), `AAD`, `None` | Empty |
| `ManagedIdentity` | Optional `clientId`, `resourceId` for a user-assigned managed identity |
| `ApiKey`, `AccountKey` | `key` |
| `AccessKey` | `accessKeyId`, `secretAccessKey` |
| `PAT`, `SAS` | `pat` or `sas`, respectively |
| `ServicePrincipal` | `clientId`, `clientSecret`, `tenantId` |
| `UsernamePassword` | `username`, `password`; optional `securityToken` |
| `OAuth2` | `clientId`, `clientSecret`; service-dependent `authUrl`, `developerToken`, `password`, `refreshToken`, `tenantId`, `username` |
| `CustomKeys` | Arbitrary nonempty key/value map, serialized as `credentials.keys` |

Credential keys use exact ARM casing. Missing required fields, blank values and
fields belonging to another authentication type are rejected. The documented
OAuth2 category-specific required fields are also checked. Additional service
configuration, such as a ServiceNow password grant, remains the caller's
responsibility.

`credentials` is a sensitive **ephemeral** input, passed only to AzAPI's
write-only `sensitive_body`. Supply it at plan and apply, preferably from an
ephemeral secret source. Secrets are not included in the persisted body or
outputs. Do not put secrets in `target` or `metadata`, which are persisted.
Increment the nonsecret `credentials_version` whenever credentials change;
the revision is stored in state and triggers credential submission on update.
Changing only an ephemeral secret cannot produce a Terraform diff.

Through the account module, keep nonsecret configuration in `project_connections`
and pass secrets separately through `project_connection_credentials`, keyed by
the same connection key. This avoids making the cardinality map sensitive.

## APIM runtime contract

The existing project must have an identity authorized by the gateway owner.
Configure project/account identities through their owning modules; attaching an
identity does not prove which runtime token is used. This contract has no explicit
per-connection UAMI selector. Verify the caller's client/principal and audience in
gateway logs before activation, without broadening access to compensate.

For APIM, the target is an HTTPS Chat Completions **base** URL, and the audience is the Entra
token resource URI, not a `/.default` scope. Static models use the connected-model deployment/model shape.
Agents must explicitly select `connectionName/gatewayDeploymentName`. This is not
an account-level AI Gateway association and does not redirect other model calls.

No discovery, deployment paths, inference/deployment API versions, custom headers
or Responses routing are configured. Verify the actual route, query, model body,
DNS/TLS/network access, token validation, gateway readiness, backend access and
request/response contract separately. Persistence and portal model visibility do
not prove successful inference.

Telemetry is enabled by default and creates an empty subscription-scoped ARM
deployment in `location`. The deployment identity needs
`Microsoft.Resources/deployments/read`, `Microsoft.Resources/deployments/write`
and `Microsoft.Resources/deployments/delete` permissions at the active
subscription scope. Set `enable_telemetry = false` to omit that deployment and
its telemetry-only location requirement.

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

For example, a keyless Search connection uses the same submodule without APIM
inputs:

```hcl
module "search_connection" {
  source = "./modules/project-connection"

  name             = "knowledge-search"
  parent_id        = var.existing_project_resource_id
  category         = "CognitiveSearch"
  auth_type        = "AAD"
  target           = var.search_endpoint
  enable_telemetry = false
  metadata = {
    ResourceId = var.search_resource_id
    location   = var.search_location
    ApiVersion = "2024-05-01-preview"
  }
}
```

Provide any additional metadata required by the service. This does not grant
the project or runtime identity access to Search.

For Registry consumption, select an actual released version containing this
submodule; v0.12.0 does not contain it. Do not treat this local example as a
released dependency.

There are no released resource-module connection addresses to migrate from
v0.12.0. Existing account, deployment and RAI-policy addresses are unchanged.
Adopting an already managed connection requires a separately reviewed state
handoff; do not configure two owners for the same connection.
