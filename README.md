# parking-infra

Infrastructure automation repository for the Parking Permit system.

## Repository Scope

This repo owns infrastructure and deployment artifacts:
- Ansible runbooks
- Docker Compose stack
- Kubernetes manifests
- Infra-level Jenkins pipeline

Application logic lives in other repos (`parking-core-api`, `parking-email-worker`, `parking-auth`).

## Structure

- `docker-compose.yml`: local/dev stack definition
- `ansible/playbooks/`: VM, Docker, K8s, Jenkins, HTTPS, verify runbooks
- `ansible/roles/`: reusable Ansible roles
- `ansible/group_vars/all.yml`: environment variables
- `k8s/`: Kubernetes manifests
- `Jenkinsfile`: infra deployment pipeline

## Prerequisites

- Linux VM with SSH access
- Ansible installed on control machine
- Docker installed on target VM
- Optional: MicroK8s for Kubernetes deployment path

## Ansible Runbooks

Inventory:

```bash
ansible/inventories/dev/hosts.ini
```

Run sequence:

```bash
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/vm-setup.yml
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/docker-deploy.yml
```

Optional K8s/Jenkins/HTTPS:

```bash
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/k8s-setup.yml
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/k8s-deploy.yml
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/jenkins-setup.yml
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/https-setup.yml
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/verify.yml
```

## Docker Compose Local Endpoints

- Core API: `http://localhost:5000`
- Keycloak: `http://localhost:8080`
- MailHog: `http://localhost:8025`
- MinIO Console: `http://localhost:9001`

## Kubernetes Notes

- Update `k8s/90-ingress.yaml` host for your domain
- Keep `ansible/group_vars/all.yml` aligned with registry/tags/FQDN

## Related Repositories

- `parking-core-api`
- `parking-email-worker`
- `parking-auth`

For cross-repo deployment instructions, use `parking-auth/MULTI-REPO-DEPLOY.md`.
