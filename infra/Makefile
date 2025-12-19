# Infrastructure as Code for lofi-stream-dlive
# All operations via Terraform only - cloud-init handles provisioning

.PHONY: init plan apply destroy status logs ssh

# Terraform operations
init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply

destroy:
	cd terraform && terraform destroy

# Get server IP from Terraform state
ip:
	@cd terraform && terraform output -raw server_ip

# SSH to server
ssh:
	@IP=$$(cd terraform && terraform output -raw server_ip 2>/dev/null) && \
	ssh -i ~/api-secrets/hetzner-server/id_ed25519 root@$$IP

# Check stream status
status:
	@IP=$$(cd terraform && terraform output -raw server_ip 2>/dev/null) && \
	ssh -i ~/api-secrets/hetzner-server/id_ed25519 root@$$IP 'systemctl status lofi-stream-dlive --no-pager'

# View stream logs
logs:
	@IP=$$(cd terraform && terraform output -raw server_ip 2>/dev/null) && \
	ssh -i ~/api-secrets/hetzner-server/id_ed25519 root@$$IP 'journalctl -u lofi-stream-dlive -f'

# View cloud-init provisioning log
provision-log:
	@IP=$$(cd terraform && terraform output -raw server_ip 2>/dev/null) && \
	ssh -i ~/api-secrets/hetzner-server/id_ed25519 root@$$IP 'cat /var/log/cloud-init-lofi.log'
