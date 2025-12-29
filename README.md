# parking-infra

Infrastructure repository for the Parking Permit system.

## Contents
- `docker-compose.yml` for local/dev stack
- `ansible/` for VM/Docker/K8s automation
- `k8s/` for Kubernetes manifests

## Local stack (docker-compose)
From this repo:
```
docker compose up -d
```

Services:
- Core API: `http://localhost:5000`
- Keycloak: `http://localhost:8080`
- MailHog UI: `http://localhost:8025`
- MinIO: `http://localhost:9001`

## Ansible
Inventory example is in `ansible/inventories/dev/hosts.ini`.

1) Base VM setup:
```
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/vm-setup.yml
```

2) Deploy with Docker:
```
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/docker-deploy.yml
```

3) MicroK8s setup:
```
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/k8s-setup.yml
```

4) Deploy to K8s:
```
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/k8s-deploy.yml
```

5) Jenkins setup:
```
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/jenkins-setup.yml
```

## Kubernetes
Apply manifests:
```
kubectl apply -f k8s/
```

Notes:
- Replace image names in `k8s/50-core-api.yaml` and `k8s/60-email-worker.yaml` with your registry images.
- Update `k8s/90-ingress.yaml` host to your FQDN.

## CI/CD (Jenkins)
Each service has a Jenkinsfile with optional Docker push and K8s deploy stages.

Optional environment variables:
- `REGISTRY`, `REGISTRY_USER`, `REGISTRY_PASS`
- `K8S_NAMESPACE`

### Jenkins setup (VM)
1) Provision a VM (Ubuntu/Debian) and SSH access.
2) Run:
```
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/jenkins-setup.yml
```
3) Open Jenkins at `http://<VM_IP>:8080` and finish the setup wizard.
4) Install plugins: **Git**, **Pipeline**, **Docker**, **Docker Pipeline**, **Kubernetes**.
5) Configure Docker on the Jenkins host:
```
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```
6) Add credentials in Jenkins:
   - Docker registry (username/password)
   - Kubeconfig (if deploying to K8s)

### Create pipelines
For each repo (`parking-core-api`, `parking-email-worker`):
1) New Item → Pipeline
2) “Pipeline script from SCM”
3) SCM: Git, Repository URL (your private repo)
4) Jenkinsfile path: `Parking.CoreApi/Jenkinsfile` or `Parking.EmailWorker/Jenkinsfile`

### Example env vars
Set these in the pipeline configuration:
- `REGISTRY=ghcr.io/theodim132`
- `REGISTRY_USER=<your-user>`
- `REGISTRY_PASS=<token>`
- `K8S_NAMESPACE=parking`

## Public deploy (HTTPS + FQDN)
Requirement: expose the system via HTTPS with a domain name.

Minimal approach:
1) Buy a domain and point an A record to your VM public IP.
2) Run the stack on a VM (Docker or K8s).
3) Put a reverse proxy (Caddy or Nginx) in front of the core API.
4) Use Let's Encrypt for TLS certificates.

Example (Caddy, on VM):
```
sudo apt-get install -y caddy
```

`/etc/caddy/Caddyfile`:
```
parking.example.com {
  reverse_proxy localhost:5000
}
```

Then:
```
sudo systemctl restart caddy
```

## Demo flows
These use the `X-Citizen-Id` header for simplicity.

1) Create application:
```
curl -X POST http://localhost:5000/api/applications \
  -H "Content-Type: application/json" \
  -H "X-Citizen-Id: citizen1" \
  -d "{\"fullName\":\"Demo Citizen\",\"address\":\"Main 1\",\"plateNumber\":\"ABC1234\",\"email\":\"citizen1@parking.local\",\"phone\":\"6900000000\"}"
```

2) List applications:
```
curl http://localhost:5000/api/applications -H "X-Citizen-Id: citizen1"
```

3) Submit application:
```
curl -X POST http://localhost:5000/api/applications/<APP_ID>/submit \
  -H "X-Citizen-Id: citizen1"
```

4) Admin decision:
```
curl -X POST http://localhost:5000/api/admin/applications/<APP_ID>/decision \
  -H "Content-Type: application/json" \
  -d "{\"status\":\"Approved\",\"reason\":\"All good\"}"
```

5) Check MailHog UI:
Open `http://localhost:8025` and view delivered email.
