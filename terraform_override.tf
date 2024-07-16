terraform {
  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
  }
}
