# Cognitive Services Account Deployment submodule

This submodule manages a single `Microsoft.CognitiveServices/accounts/deployments` resource (model deployment) under a parent Cognitive Services / AI Services account.

It is consumed automatically by the parent module via `var.cognitive_deployments`, and can also be consumed directly when finer-grained control over deployment lifecycle and dependencies is required.

Set `tags` directly, or `cognitive_deployments[*].tags` through the parent module. Omitted or null tags retain provider defaults without inheriting account tags; an empty map explicitly selects no tags.

> [!NOTE]
> Per the AVM specification [TFRMNFR1](https://azure.github.io/Azure-Verified-Modules/spec/TFRMNFR1), this submodule deploys exactly one deployment per instance. Use `for_each` / `count` on the parent `module` call to manage multiple deployments.
