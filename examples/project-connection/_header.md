# Project APIM connection (preview)

This standalone example deploys one connection using this repository's
`modules/project-connection` submodule. It uses only AzAPI and does not create,
adopt or modify an account, project, gateway, identity, network or role assignment.

## Prerequisites

- An existing Foundry project and an existing APIM Chat Completions gateway.
- A project identity already authorized by the gateway owner, with the correct
  token audience and network access. No per-connection UAMI selector is provided.
- A gateway model alias matching the static `models` catalog. The example's
  default `chat` alias is illustrative; configure it to match the actual gateway.
- Terraform 1.11 or later and Azure authentication authorized to manage
  `Microsoft.CognitiveServices/accounts/projects/connections` in that project.
- A connection name not already managed elsewhere. This example does not import
  existing connections.

The connection uses preview `ApiManagement` and `ProjectManagedIdentity` fields.
See the [submodule contract](../../modules/project-connection/README.md) for schema
limitations and runtime prerequisites. Local validation does not establish Azure
acceptance or release readiness.

## Run

From this directory, authenticate to Azure using your approved credential flow
and supply the existing infrastructure through environment variables:

```powershell
$env:TF_VAR_parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.CognitiveServices/accounts/example-foundry/projects/research"
$env:TF_VAR_target = "https://gateway.example.com/ai/v1"
$env:TF_VAR_audience = "api://gateway"
$env:TF_VAR_enable_telemetry = "false"

terraform init
terraform plan -out=connection.tfplan
terraform apply connection.tfplan
terraform output model_references
```

Replace the placeholder project ID, gateway URL and audience before running.
Telemetry is explicitly disabled in this invocation; the input retains the
standard default of `true`. When telemetry is enabled, supply the appropriate
`location` and ensure the deployment identity has
`Microsoft.Resources/deployments/read`, `Microsoft.Resources/deployments/write`
and `Microsoft.Resources/deployments/delete` at the active subscription scope.

The default catalog produces `chat = "enterprise-models/chat"`. An agent must
explicitly select this reference. Connection creation and catalog visibility do
not verify gateway routes, token validation, backend access or successful
inference. No inference requests are made by this example.

To remove only this example's connection, keep the same input values and run
`terraform destroy` from this directory. If telemetry was enabled, its empty
subscription deployment is also removed. The account, project and gateway are
external prerequisites and are not destroyed by this configuration.

The existing-project scenario deliberately consumes the child directly. For the
account module's `project_connections` composition interface, see the
[root usage example](../../README.md#example-use-the-connection-child-through-the-account-module).
Do not pass a separately created project's dependency back into its own account
module; direct child consumption avoids that dependency cycle.
