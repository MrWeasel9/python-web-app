terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.46.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "1.13.3"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.0.2"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.vmradu-aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.vmradu-aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.vmradu-aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.vmradu-aks.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.vmradu-aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.vmradu-aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.vmradu-aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.vmradu-aks.kube_config[0].cluster_ca_certificate)
  }
}

resource "azurerm_resource_group" "vmradu-rg" {
  name     = "vmradu-rg"
  location = "North Europe"
}

resource "azurerm_kubernetes_cluster" "vmradu-aks" {
  name                = "vmradu-aks"
  location            = azurerm_resource_group.vmradu-rg.location
  resource_group_name = azurerm_resource_group.vmradu-rg.name
  dns_prefix          = "vmradu-aks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_container_registry" "vmraduacr" {
  name                = "vmraduacr"
  resource_group_name = azurerm_resource_group.vmradu-rg.name
  location            = azurerm_resource_group.vmradu-rg.location
  sku                 = "Standard"
  admin_enabled       = true
}

data "azurerm_kubernetes_cluster" "vmradu-aks" {
  name                = azurerm_kubernetes_cluster.vmradu-aks.name
  resource_group_name = azurerm_resource_group.vmradu-rg.name
}

resource "azurerm_role_assignment" "vmraduacr" {
  scope                = azurerm_container_registry.vmraduacr.id
  role_definition_name = "AcrPull"
  principal_id         = data.azurerm_kubernetes_cluster.vmradu-aks.kubelet_identity[0].object_id
}

resource "kubernetes_namespace" "development" {
  metadata {
    name = "development"
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "kube-system"
  version    = "4.0.13" # Specify a known stable version

  set {
    name  = "controller.replicaCount"
    value = 2
  }
}

