# Local Authentication Disabled Example

This deploys an Azure OpenAI service with local authentication disabled (`local_auth_enabled = false`). This example demonstrates the scenario described in issue #130 where the module fails when trying to list account keys on a service with disabled local authentication.

**Expected Behavior**: 
- Before fix: Deployment fails with "Failed to list key. disableLocalAuth is set to be true"
- After fix: Deployment succeeds with `primary_access_key` and `secondary_access_key` outputs set to `null`
