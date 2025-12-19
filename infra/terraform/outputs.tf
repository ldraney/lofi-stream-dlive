output "server_ip" {
  description = "Public IPv4 address of the DLive stream server"
  value       = hcloud_server.dlive.ipv4_address
}

output "server_status" {
  description = "Server status"
  value       = hcloud_server.dlive.status
}

output "ssh_command" {
  description = "SSH command to connect to server"
  value       = "ssh -i ~/api-secrets/hetzner-server/id_ed25519 root@${hcloud_server.dlive.ipv4_address}"
}

output "monthly_cost" {
  description = "Estimated monthly cost"
  value       = "~$6.99 USD/month (CPX22)"
}
