data "azapi_client_config" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}
