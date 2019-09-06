variable "prefix" { default = "" }
variable "ssh_key_name" { default = "" }
variable "cluster_size" { default = 3 }
variable "ami_id" { default = "" }
variable "ami_filter_owners" {
  description = "When bash install method, use a filter to lookup an image owner and name. Common combinations are 206029621532 and amzn2-ami-hvm* for Amazon Linux 2 HVM, and 099720109477 and ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-* for Ubuntu 18.04"
  type        = list(string)
  default     = ["099720109477"]
}
variable "ami_filter_name" {
  description = "When bash install method, use a filter to lookup an image owner and name. Common combinations are 206029621532 and amzn2-ami-hvm* for Amazon Linux 2 HVM, and 099720109477 and ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-* for Ubuntu 18.04"
  type        = list(string)
  default     = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
}
variable "vpc_id" { default = "" }
variable "subnet_ids" { default = "" }
variable "consul_ent_license" { default = "" }
variable "vault_ent_license" { default = "" }
variable "consul_version" { default = "" }
variable "download_url" { default = "" }
variable "cluster_tag_key" { default = "consul-servers" }
variable "cluster_tag_value" { default = "auto-join" }
variable "path" { default = "/opt/consul" }
variable "user" { default = "" }
variable "ca_path" { default = "" }
variable "cert_file_path" { default = "" }
variable "key_file_path" { default = "" }
variable "server" { default = true }
variable "client" { default = false }
variable "config_dir" { default = "" }
variable "data_dir" { default = "" }
variable "systemd_stdout" { default = "" }
variable "systemd_stderr" { default = "" }
variable "bin_dir" { default = "" }
variable "datacenter" { default = "" }
variable "autopilot_cleanup_dead_servers" { default = "" }
variable "autopilot_last_contact_threshold" { default = "" }
variable "autopilot_max_trailing_logs" { default = "" }
variable "autopilot_server_stabilization_time" { default = "" }
variable "autopilot_redundancy_zone_tag" { default = "az" }
variable "autopilot_disable_upgrade_migration" { default = "" }
variable "autopilot_upgrade_version_tag" { default = "" }
variable "enable_gossip_encryption" { default = true }
variable "gossip_encryption_key" { default = "" }
variable "enable_rpc_encryption" { default = true }
variable "environment" { default = "" }
variable "skip_consul_config" { default = "" }
variable "recursor" { default = "" }
variable "tags" {
  description = "List of extra tag blocks added to the autoscaling group configuration. Each element in the list is a map containing keys 'key', 'value', and 'propagate_at_launch' mapped to the respective values."
  type        = map
  default     = {}
}
variable "enable_acls" { default = false }
