$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$keyPath = "C:\Users\teror\Downloads\it214145_key.pem"
$inventory = "ansible/inventories/azure/hosts.ini"
$ansibleImage = "cytopia/ansible:latest"
$plays = @(
  "ansible/playbooks/vm-setup.yml",
  "ansible/playbooks/jenkins-setup.yml",
  "ansible/playbooks/k8s-setup.yml",
  "ansible/playbooks/k8s-deploy.yml",
  "ansible/playbooks/https-setup.yml"
)

if (-not (Test-Path $keyPath)) {
  throw "SSH key not found at $keyPath"
}

foreach ($play in $plays) {
  Write-Host "Running $play..." -ForegroundColor Cyan
  docker run --rm -it `
    -v "${repoRoot}:/work" `
    -v "${keyPath}:/root/.ssh/id_rsa" `
    $ansibleImage sh -lc `
    "apk add --no-cache openssh-client && chmod 600 /root/.ssh/id_rsa && cd /work && ANSIBLE_CONFIG=/work/ansible.cfg ansible-playbook -i $inventory -e ansible_ssh_private_key_file=/root/.ssh/id_rsa $play"
  if ($LASTEXITCODE -ne 0) { throw "Playbook failed: $play" }
}

Write-Host "All playbooks completed." -ForegroundColor Green
