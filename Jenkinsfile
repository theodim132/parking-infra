pipeline {
  agent any
  parameters {
    string(name: 'CORE_API_TAG', defaultValue: 'latest', description: 'Docker image tag for core API')
    string(name: 'EMAIL_WORKER_TAG', defaultValue: 'latest', description: 'Docker image tag for email worker')
    booleanParam(name: 'DEPLOY_EMAIL_WORKER', defaultValue: false, description: 'Deploy email worker')
  }
  environment {
    REGISTRY = "localhost:32000"
    K8S_NAMESPACE = "parking"
  }
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
          microk8s kubectl rollout status deployment/postgres -n $K8S_NAMESPACE --timeout=2m
          microk8s kubectl delete job/parking-migrate -n $K8S_NAMESPACE --ignore-not-found
          microk8s kubectl apply -f k8s/55-migrate.yaml
          microk8s kubectl set image job/parking-migrate migrate=$REGISTRY/parking-core-api:$CORE_API_TAG -n $K8S_NAMESPACE
          microk8s kubectl wait --for=condition=complete job/parking-migrate -n $K8S_NAMESPACE --timeout=5m
          if [ "${DEPLOY_EMAIL_WORKER}" = "true" ]; then
            microk8s kubectl apply -f k8s/60-email-worker.yaml
          fi
          microk8s kubectl apply -f k8s/95-cert-manager.yaml
          microk8s kubectl apply -f k8s/90-ingress.yaml
          microk8s kubectl set image deployment/core-api core-api=$REGISTRY/parking-core-api:$CORE_API_TAG -n $K8S_NAMESPACE
          if [ "${DEPLOY_EMAIL_WORKER}" = "true" ]; then
            microk8s kubectl set image deployment/email-worker email-worker=$REGISTRY/parking-email-worker:$EMAIL_WORKER_TAG -n $K8S_NAMESPACE
          fi
          microk8s kubectl rollout status deployment/core-api -n $K8S_NAMESPACE --timeout=2m
          if [ "${DEPLOY_EMAIL_WORKER}" = "true" ]; then
            microk8s kubectl rollout status deployment/email-worker -n $K8S_NAMESPACE --timeout=2m
          fi
        '''
      }
    }
  }
}
