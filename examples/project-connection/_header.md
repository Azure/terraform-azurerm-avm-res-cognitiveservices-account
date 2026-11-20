# Project APIM connection (preview)

This runnable example consumes `modules/project-connection` directly. It always
provisions isolated, uniquely named prerequisites in the authenticated Azure
subscription and passes their actual IDs and endpoint to the connection.
Terraform owns resource creation, dependencies and cleanup; no hook, shared
infrastructure ID, external-infrastructure mode or placeholder input is required.
All resources and the module call are in `main.tf`.

## Resources and prerequisites

The example uses AzAPI to create:

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
Model deployments explicitly depend on project creation. They also share an
account-scoped AzAPI lock with the project because concurrent child operations
can return `RequestConflict`, including concurrent model deployments. This is a
provider-process mutex, not an Azure management lock.
The API policy depends on the Chat Completions operation so Terraform deletes
the policy before the operation instead of modifying both API children concurrently.
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
The APIM gateway allows 60 minutes each for creation, updates and deletion;
the CI job must allow additional time for the remaining resources and cleanup.

The isolated fixture uses public gateway and backend endpoints secured by Entra
tokens and managed identities, not API keys. It is not a private-network
production blueprint. This fixture does not configure virtual-network integration;
consume the submodule directly for a gateway with existing private-network connectivity.
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
`terraform destroy`; this removes the connection **and all example resources**,
including its resource group. Verify cleanup independently.

## Existing project and gateway

This example no longer accepts `parent_id`, `target` or `audience` overrides.
For existing infrastructure, use the direct call in the
[submodule documentation](../../modules/project-connection/README.md#composition)
and supply the required connection inputs in your own configuration. The
submodule never creates projects, gateways, models or authorization.

The `moved` blocks preserve the prior example's singleton `[0]` resource
addresses after removing conditional creation. Names, bodies and dependency
ordering remain unchanged. Review the plan before reusing an existing example
state. These moves do not convert the former external-only mode: keep that
configuration for cleanup or consume the submodule in a separate configuration;
applying this example would create all prerequisites.

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
