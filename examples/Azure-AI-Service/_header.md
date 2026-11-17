# Azure AI Service example

This deploys an Azure AI service linked to an Azure Machine Learning workspace, using a user-assigned managed identity and platform-managed encryption.

The example remains enabled for end-to-end testing. It does not create a Managed HSM because AVM test subscriptions block ephemeral HSM deployments to prevent runaway costs. HSM-backed customer-managed key testing requires approved shared persistent infrastructure and is not covered by this example.
