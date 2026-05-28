# Cognitive Services Account RAI Policy submodule

This submodule manages a single `Microsoft.CognitiveServices/accounts/raiPolicies` resource (Responsible AI content moderation policy) under a parent Cognitive Services / AI Services account.

It is consumed automatically by the parent module via `var.rai_policies`, and can also be consumed directly when finer-grained control over RAI policy lifecycle is required.

> [!NOTE]
> Per the AVM specification [TFRMNFR1](https://azure.github.io/Azure-Verified-Modules/spec/TFRMNFR1), this submodule deploys exactly one RAI policy per instance. Use `for_each` / `count` on the parent `module` call to manage multiple policies.
