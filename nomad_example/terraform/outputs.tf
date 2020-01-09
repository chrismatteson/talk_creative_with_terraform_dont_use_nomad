output "IP_Addresses" {
  value = <<CONFIGURATION

Client public IPs: ${join(", ", module.nomadconsul.client_public_ips)}
Client private IPs: ${join(", ", module.nomadconsul.client_private_ips)}
Windows Client public IPs: ${join(", ", module.nomadconsul.windows_client_public_ips)}
Windows Client private IPs: ${join(", ", module.nomadconsul.windows_client_private_ips)}
Server public IPs: ${join(", ", module.nomadconsul.primary_server_public_ips)}
Server private IPs: ${join(", ", module.nomadconsul.primary_server_private_ips)}

Nomad bootstrap token: ${module.nomadconsul.bootstrap_token}
Windows Client password: ${join(", ", module.nomadconsul.windows_password)}

`ssh -i "${var.key_name}.pem" ubuntu@${element(module.nomadconsul.primary_server_public_ips, 0)}`

The Consul UI can be accessed at http://${element(module.nomadconsul.primary_server_public_ips, 0)}:8500/ui
The Nomad UI can be accessed at http://${element(module.nomadconsul.primary_server_public_ips, 0)}:4646/ui

CONFIGURATION

}

