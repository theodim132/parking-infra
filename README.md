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
- `k8s/50-core-api.yaml` and `k8s/60-email-worker.yaml` pull from `localhost:32000`, which is the MicroK8s registry as seen by the cluster.
- Jenkins pushes to `172.20.173.171:32000`. Same registry, different hostname.
- Update `k8s/90-ingress.yaml` host to your FQDN.

### Access (no port-forward)
Core API and Keycloak are exposed as NodePort services:
- Core API: `http://<node_ip>:30080`
- Keycloak: `http://<node_ip>:30081`

If you want a public HTTPS link without buying a domain, use a quick Cloudflare tunnel:
```
cloudflared tunnel --url http://localhost:30080
```
This prints a public `https://*.trycloudflare.com` URL you can share for the demo.

## CI/CD (Jenkins)
Each service has a Jenkinsfile with:
- Restore/Build/Test
- Docker build
- Ansible K8s deploy (targets MicroK8s)
- Optional Docker push to registry

Defaults baked in the Jenkinsfiles:
- `REGISTRY=localhost:32000` (MicroK8s registry on the same VM)
- `K8S_NAMESPACE=parking`
- `INFRA_REPO=https://github.com/theodim132/parking-infra.git`
- Credentials id for private Git: `39aaae8f-ea94-4bf7-88a9-1bc9f29b36a6`

If you want automatic push, set in the Jenkins job:
- `REGISTRY=localhost:32000`
- (Optional) `REGISTRY_USER` / `REGISTRY_PASS` if your registry needs auth

## Jenkins Access
- URL: `https://parking-demo.swedencentral.cloudapp.azure.com/jenkins` (or `http://20.240.193.212:8080/jenkins`)
- Username: `admin`
- Password: `ChangeMe_123!_Now`
- Source: `/var/lib/jenkins/init.groovy.d/02-create-admin.groovy`
- Action: change this password after first login.

## Nginx vs MicroK8s Ingress
- Only one MicroK8s install is present.
- MicroK8s ingress spawns its own nginx master (`/usr/bin/nginx`) and binds 443.
- This conflicts with the VM Nginx reverse proxy and caused 404s on `/jenkins`.
- Fix: `https-setup.yml` disables MicroK8s ingress and resets Nginx to use only `/etc/nginx/sites-enabled/parking`.
- If you need ingress later, choose one public entrypoint (either ingress OR VM Nginx) on port 443.

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

### Example pipeline setup
- Create pipeline “parking-core-api”, Jenkinsfile path: `Parking.CoreApi/Jenkinsfile`
- Create pipeline “parking-email-worker”, Jenkinsfile path: `Parking.EmailWorker/Jenkinsfile`
- Set branch trigger to master (poll SCM or webhook)
- Ensure Docker available in Jenkins, and SSH access to the MicroK8s host (`host.docker.internal`).

### Push→Deploy flow (MicroK8s)
1) Push to `master`.
2) Jenkins: restore/build/test → docker build → (optional push to registry) → Ansible applies `parking-infra/k8s` to namespace `parking`.
3) Verify: `wsl -d Ubuntu -- microk8s kubectl -n parking get pods,svc`.

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
# Webhook test
