terraform {
  required_version = ">= 0.11.10"
}

provider "aws" {
  region = var.region
}

provider "nomad" {
  address   = "http://${module.nomadconsul.primary_server_public_ips[0]}:4646"
  secret_id = module.nomadconsul.bootstrap_token
}

module "network" {
  source = "./modules/network"

  vpc_cidr        = var.vpc_cidr
  name_tag_prefix = var.name_tag_prefix
  subnet_cidr     = var.subnet_cidr
  subnet_az       = var.subnet_az
}

module "nomadconsul" {
  source = "./modules/nomadconsul"

  region               = var.region
  ami                  = var.ami
  vpc_id               = module.network.vpc_id
  subnet_id            = module.network.subnet_id
  server_instance_type = var.server_instance_type
  client_instance_type = var.client_instance_type
  key_name             = var.key_name
  server_count         = var.server_count
  client_count         = var.client_count
  name_tag_prefix      = var.name_tag_prefix
  cluster_tag_value    = var.cluster_tag_value
  owner                = var.owner
  ttl                  = var.ttl
  private_key_data     = var.private_key_data

  # We don't actually use the following
  # but want the aws_instance.primary in the module to depend on it
  route_table_association_id = module.network.route_table_association_id
}

# Nomad namespace: dev
resource "nomad_namespace" "dev" {
  name        = "dev"
  description = "Shared development environment."
  depends_on = [
    module.nomadconsul,
  ]
}

# Nomad namespace: qa
resource "nomad_namespace" "qa" {
  name        = "qa"
  description = "Shared QA environment."
  depends_on = [
    module.nomadconsul,
  ]
}

# Nomad ACL policy: anonymous
resource "nomad_acl_policy" "anonymous" {
  name        = "anonymous"
  description = "restricted access for users without ACL tokens"
  rules_hcl   = file("${path.module}/acls/anonymous.hcl")
  depends_on  = [module.nomadconsul]
}

# Nomad ACL policy: dev
resource "nomad_acl_policy" "dev" {
  name        = "dev"
  description = "access for users with dev ACL tokens"
  rules_hcl   = file("${path.module}/acls/dev.hcl")
  depends_on  = [module.nomadconsul]
}

# Nomad ACL policy: qa
resource "nomad_acl_policy" "qa" {
  name        = "qa"
  description = "access for users with qa ACL tokens"
  rules_hcl   = file("${path.module}/acls/qa.hcl")
  depends_on  = [module.nomadconsul]
}

# Nomad ACL token: alice (dev)
resource "nomad_acl_token" "alice" {
  name       = "alice"
  type       = "client"
  policies   = ["dev"]
  depends_on = [module.nomadconsul]
}

# Nomad ACL token: bob (qa)
resource "nomad_acl_token" "bob" {
  name       = "bob"
  type       = "client"
  policies   = ["qa"]
  depends_on = [module.nomadconsul]
}

# Template File for stop_all_jobs.sh script
data "template_file" "stop_all_jobs" {
  template = file("${path.module}/stop_all_jobs.sh")

  vars = {
    bootstrap_token = module.nomadconsul.bootstrap_token
    address         = "http://${module.nomadconsul.primary_server_private_ips[0]}:4646"
  }
}

resource "null_resource" "stop_all_jobs" {
  # We stop all jobs because not doing so causes
  # problems when running `terraform destroy`
  # Note that is this a destroy provisioner only run
  # when we run `terraform destroy`

  provisioner "file" {
    content     = data.template_file.stop_all_jobs.rendered
    destination = "~/stop_all_jobs.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/stop_all_jobs.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "~/stop_all_jobs.sh",
    ]
    when = destroy
  }

  connection {
    host        = module.nomadconsul.primary_server_public_ips[0]
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = var.private_key_data
  }

}

