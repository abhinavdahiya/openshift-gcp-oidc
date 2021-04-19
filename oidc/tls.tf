resource "tls_private_key" "signing_key" {
  algorithm = "RSA"
}

resource "local_file" "signing_key_public_pem" {
  content  = tls_private_key.signing_key.public_key_pem
  filename = "${path.module}/signing_key_public.pem"
}

resource "null_resource" "keys_json_file" {
  triggers = {
    fingerprint = tls_private_key.signing_key.public_key_fingerprint_md5
  }

  provisioner "local-exec" {
    command     = "go run generate.go -key ../../${path.module}/signing_key_public.pem > ../../${path.module}/keys.json"
    working_dir = "./scripts/json_web_key/"
  }

  depends_on = [local_file.signing_key_public_pem]
}
