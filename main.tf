terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }

    google-beta = {
      source = "hashicorp/google-beta"
    }

    tls = {
      source = "hashicorp/tls"
    }
  }
}


provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "oidc" {
  source = "./oidc"

  name          = var.name
  identity_pool = var.identity_pool
}

module "sa_image_registry" {
  source = "./service_account"

  name          = "${var.name}-image-registry"
  identity_pool = var.identity_pool
  iam_namespace = var.name

  service_accounts = [
    { namespace = "openshift-image-registry", name = "cluster-image-registry-operator" },
    { namespace = "openshift-image-registry", name = "registry" }
  ]
  secret = { namespace = "openshift-image-registry", name = "installer-cloud-credentials", token_path = "/var/run/secrets/openshift/serviceaccount/token" }

  bindings = [
    "roles/storage.admin"
  ]
}

module "sa_ingress" {
  source = "./service_account"

  name          = "${var.name}-ingress"
  identity_pool = var.identity_pool
  iam_namespace = var.name

  service_accounts = [
    { namespace = "openshift-ingress-operator", name = "ingress-operator" }
  ]
  secret = { namespace = "openshift-ingress-operator", name = "cloud-credentials", token_path = "/var/run/secrets/openshift/serviceaccount/token" }

  bindings = [
    "roles/dns.admin"
  ]
}

module "sa_machine_api" {
  source = "./service_account"

  name          = "${var.name}-machine-api"
  identity_pool = var.identity_pool
  iam_namespace = var.name

  service_accounts = [
    { namespace = "openshift-machine-api", name = "machine-api-controllers" }
  ]
  secret = { namespace = "openshift-machine-api", name = "aws-cloud-credentials", token_path = "/var/run/secrets/openshift/serviceaccount/token" }

  bindings = [
    "roles/compute.instanceAdmin.v1",
    "roles/compute.loadBalancerAdmin"
  ]
}

module "sa_pd_csi_driver" {
  source = "./service_account"

  name          = "${var.name}-pd-csi-driver"
  identity_pool = var.identity_pool
  iam_namespace = var.name

  service_accounts = [
    { namespace = "openshift-cluster-csi-drivers", name = "gcp-pd-csi-driver-operator" },
    { namespace = "openshift-cluster-csi-drivers", name = "gcp-pd-csi-driver-controller-sa" }
  ]
  secret = { namespace = "openshift-cluster-csi-drivers", name = "gcp-pd-cloud-credentials", token_path = "/var/run/secrets/openshift/serviceaccount/token" }

  bindings = [
    "roles/compute.instanceAdmin",
    "roles/compute.storageAdmin"
  ]
}


locals {
  secret_files = {
    "manifests/secret-credentials-image-registry.yaml" : module.sa_image_registry.secret,
    "manifests/secret-credentials-ingress.yaml" : module.sa_ingress.secret,
    "manifests/secret-credentials-machine-api.yaml" : module.sa_machine_api.secret,
    "manifests/secret-credentials-ebs-csi-driver.yaml" : module.sa_pd_csi_driver.secret,
  }

  authentication_files = {
    "manifests/cluster-authentication-02-config.yaml" : yamlencode({
      "apiVersion" : "config.openshift.io/v1",
      "kind" : "Authentication",
      "metadata" : {
        "name" : "cluster"
      }
      "spec" : {
        "serviceAccountIssuer" : module.oidc.issuer.url
      }
    })
  }
}

resource "local_file" "output" {
  for_each = merge(local.secret_files, local.authentication_files)
  content  = each.value
  filename = "${path.module}/_output/${each.key}"
}

resource "local_file" "output_tls" {
  sensitive_content = module.oidc.signing_key_pem
  filename          = "${path.module}/_output/tls/bound-service-account-signing-key.key"
}
