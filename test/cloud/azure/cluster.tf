locals {
  version = replace(var.kube_version, ".", "-")
  name    = "${var.name_prefix}-v${local.version}-run-${var.github_run_number}"

  tags = {
    Environment = "github-ci"
    Workflow    = "CI"
    Repository  = "oob-ebpf"
    RunID       = var.github_run_id
    RunNumber   = var.github_run_number
  }
}

resource "azurerm_resource_group" "main" {
  location = var.location
  name     = local.name
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = local.name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}

resource "azurerm_role_assignment" "network_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id

  skip_service_principal_aad_check = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  location            = azurerm_resource_group.main.location
  name                = local.name
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = local.name
  kubernetes_version  = var.kube_version
  tags                = local.tags

  public_network_access_enabled   = true

  api_server_access_profile {
    authorized_ip_ranges = ["0.0.0.0/0"]
  }

  default_node_pool {
    name       = "defaultpool"
    os_sku     = "Ubuntu"
    vm_size    = "Standard_D2_v2"
    node_count = var.node_count

    enable_auto_scaling = false
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }
}