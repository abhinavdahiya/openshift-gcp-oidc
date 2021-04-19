variable "name" {
  type = string
}

variable identity_pool {
  type = string
}

variable "iam_namespace" {
  type = string
}

variable service_accounts {
  type = list(object({
    namespace = string
    name      = string
  }))
}

variable bindings {
  type = list(string)
}

variable secret {
  type = object({
    namespace  = string
    name       = string
    token_path = string
  })
}
