# Deployment Runbook

Infrastructure deployment reference for a fresh Ubuntu 22.04 VM.

## Scope

This document covers infrastructure and runtime deployment from `parking-infra`.

## Prerequisites

- VM with 2+ vCPU and 4GB+ RAM
- SSH key access to the VM
- Ansible installed on the control machine

## Inventory

Inventory file:

```bash
ansible/inventories/azure/hosts.ini
```

## Playbook Execution

```bash
ansible-playbook -i ansible/inventories/azure/hosts.ini \
  ansible/playbooks/vm-setup.yml \
  ansible/playbooks/k8s-setup.yml \
  ansible/playbooks/k8s-deploy.yml \
  ansible/playbooks/jenkins-setup.yml \
  ansible/playbooks/https-setup.yml
```

## Installed Components

- MicroK8s (Kubernetes)
- PostgreSQL
- Keycloak
- MinIO
- MailHog
- Core API and Email Worker workloads
- Jenkins
- Nginx with Let's Encrypt certificates

## Image Build and Push on VM

```bash
ssh user@vm

# Core API
cd /tmp && git clone <repo>
cd parking-core-api/Parking.CoreApi
docker build -t localhost:32000/parking-core-api:latest .
docker push localhost:32000/parking-core-api:latest

# Email Worker
cd /tmp && git clone <repo>
cd parking-email-worker/Parking.EmailWorker
docker build -t localhost:32000/parking-email-worker:latest .
docker push localhost:32000/parking-email-worker:latest

# Restart workloads
microk8s kubectl rollout restart deployment/core-api deployment/email-worker -n parking
```

## Keycloak Realm Import

```bash
scp parking-auth/realm/parking-realm.json user@vm:/tmp/
ssh user@vm
microk8s kubectl cp /tmp/parking-realm.json parking/keycloak-0:/tmp/
microk8s kubectl exec -n parking keycloak-0 -- /opt/keycloak/bin/kc.sh import --file /tmp/parking-realm.json
```

## Service URLs

- App: `https://<fqdn>/`
- Keycloak: `https://<fqdn>/auth`
- Jenkins: `https://<fqdn>/jenkins`
- MailHog: `https://<fqdn>/mailhog/`
