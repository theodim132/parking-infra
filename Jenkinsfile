pipeline {
  agent any
  stages {
    stage('Apply Manifests') {
      steps {
        sh '''
          set -e
          microk8s kubectl apply -f k8s/00-namespace.yaml
          microk8s kubectl apply -f k8s/01-config.yaml
          microk8s kubectl apply -f k8s/10-postgres.yaml
          microk8s kubectl apply -f k8s/20-keycloak.yaml
          microk8s kubectl apply -f k8s/30-mailhog.yaml
          microk8s kubectl apply -f k8s/40-minio.yaml
          microk8s kubectl apply -f k8s/50-core-api.yaml
          microk8s kubectl apply -f k8s/60-email-worker.yaml
          microk8s kubectl apply -f k8s/90-ingress.yaml
        '''
      }
    }
  }
}
