# Project APIM connection (preview)

This runnable example consumes `modules/project-connection` directly. By default
it provisions isolated, uniquely named prerequisites in the authenticated Azure
subscription and passes their actual IDs and endpoint to the connection. Like
the repository's other runnable examples, Terraform owns fixture creation,
dependencies and cleanup; no hook, shared infrastructure ID or placeholder
deployment input is required.

## Isolated example / E2E mode

Leave `parent_id`, `target` and `audience` null (their defaults). The example uses
AzAPI to create:

- A resource group and an AIServices account with project management enabled,
  system-assigned identity and local authentication disabled.
- A Foundry project with its own system-assigned identity.
- A GlobalStandard deployment (capacity 1) for each alias in `models`. The default
  is `chat`, backed by `gpt-4.1-mini`, version `2025-04-14`.
- An APIM Premium gateway with two units across availability zones `1` and `2`,
  system-assigned identity and an HTTPS
  `POST /ai/v1/chat/completions` route forwarding to the account's OpenAI v1 API.
- An API policy validating the tenant, Cognitive Services token audience and
  project identity's `oid` claim. APIM authenticates to the backend using its own
  managed identity and an account-scoped Cognitive Services OpenAI User role.

The connection uses the created project's ARM ID, the gateway's Azure-returned
`gatewayUrl` plus `/ai/v1`, and the actual Cognitive Services Entra resource URI,
`https://cognitiveservices.azure.com` (not a `/.default` scope).
The reserved publisher contact `avm-tests@example.com` is fixture metadata only;
use an appropriate monitored contact if adapting this gateway for production.

Use an explicitly approved isolated subscription and region supporting Foundry
projects, APIM Premium in zones `1` and `2`, and the selected model versions and GlobalStandard
quota. The deploying identity needs resource-group, Cognitive Services and APIM
management permissions, plus role-assignment write/delete on the created account.
Resource providers must already be registered; this example does not register
providers or subscription features. Two Premium units incur substantially higher
cost than Consumption and can take significant time to provision; approve the
cost and cleanup scope before running the example.

The isolated fixture uses public gateway and backend endpoints secured by Entra
tokens and managed identities, not API keys. It is not a private-network
production blueprint. This fixture does not configure virtual-network integration;
use external mode for a gateway with existing private-network connectivity.
Existing organizational and AVM policy gates still apply;
no policy exceptions or deployment exclusions are supplied. Do not deploy this
fixture where public endpoints are prohibited.

After obtaining deployment and cleanup authorization, from the repository root:

```powershell
Import-Module Avm.Authoring
avm test e2e --example project-connection
```

The managed E2E runner applies, checks refreshed idempotency, and destroys the
example. It does not send an inference request. Connection creation, ARM route
configuration and catalog visibility are not proof of token acquisition,
backend access, RBAC propagation or successful inference.
Provider-mocked unit tests prove wiring only, not Azure acceptance. Real Azure
E2E and policy validation must pass separately before readiness is claimed.

For manual deployment, run `terraform init`, inspect a saved `terraform plan`,
then apply only after authorization. Keep the same state and inputs for
`terraform destroy`; in fixture mode this removes the connection **and all
fixture resources**, including its resource group. Verify cleanup independently.

## Existing project and gateway

To create only a connection against infrastructure owned elsewhere, supply
**all three** of `parent_id`, `target` and `audience`. Partial external inputs are
rejected. With all three supplied the example creates no account, project,
gateway, model deployment, network or role assignment and does not adopt them.
The reusable child still requires its inputs explicitly and never provisions a
fixture.

- Use the real ARM ID of an existing Foundry project.
- Supply an existing HTTPS Chat Completions base URL without a trailing slash,
  operation path, query or fragment, and its Entra token resource URI.
- The project identity must already be authorized by the gateway owner with
  correct token validation, network access and backend access. There is no
  per-connection UAMI selector.
- Set `models` to the gateway's actual deployment aliases. The default catalog
  produces `chat = "enterprise-models/chat"`; an agent must select that reference
  explicitly. In external mode the connection does not deploy models or routes.
- Choose a connection name not already managed elsewhere. No import is performed.

Set `TF_VAR_parent_id`, `TF_VAR_target` and `TF_VAR_audience` through your approved
environment or protected variable file, then run `terraform init` and inspect
`terraform plan -out=connection.tfplan` before applying. Do not copy fixture IDs
or invent example subscription IDs. Keep the same external input values and
state for `terraform destroy`; only the connection and any enabled deployment
telemetry are removed, not the external prerequisites.

Do not switch an applied state between fixture and external modes: that would
plan deletion of the fixture prerequisites and replacement of the connection.
Use a separate state for an existing-project deployment.

## Contract and telemetry

The connection uses preview `ApiManagement` and `ProjectManagedIdentity` fields.
See the [submodule contract](../../modules/project-connection/README.md) for schema
limitations and runtime prerequisites.

`enable_telemetry` defaults to `true`; CI may explicitly disable it. When enabled,
the deployment identity also needs `Microsoft.Resources/deployments/read`,
`Microsoft.Resources/deployments/write` and
`Microsoft.Resources/deployments/delete` at the active subscription scope.

For the account module's `project_connections` composition interface, see the
[root usage example](../../README.md#example-use-the-connection-child-through-the-account-module).
Do not pass a separately created project's dependency back into its own account
module; direct child consumption avoids that dependency cycle.
