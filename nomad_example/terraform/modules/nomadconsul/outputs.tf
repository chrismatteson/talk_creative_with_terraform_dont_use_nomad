# Outputs
output "primary_server_private_ips" {
  value = aws_instance.primary.*.private_ip
}

output "primary_server_public_ips" {
  value = aws_instance.primary.*.public_ip
}

output "bootstrap_token" {
  value = data.external.get_bootstrap_token.result["bootstrap_token"]
}

output "client_private_ips" {
  value = aws_instance.client.*.private_ip
}

output "client_public_ips" {
  value = aws_instance.client.*.public_ip
}

output "windows_client_public_ips" {
  value = aws_instance.windows_client.*.public_ip
}

output "windows_client_private_ips" {
  value = aws_instance.windows_client.*.private_ip
}

output "windows_password" {
  value = data.external.decode_password[*].result.decrypted_password
}
