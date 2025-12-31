pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  serviceAccountName: jenkins-sa
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    tty: true
    resources:
      requests:
        cpu: "50m"
        memory: "128Mi"
      limits:
        cpu: "100m"
        memory: "256Mi"
"""
        }
    }
    
    environment {
        // AWS Configuration
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER_NAME = 'microservices-cluster'
        
        // Docker Configuration
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKERHUB_USERNAME = 'hushhrf'
        DOCKERHUB_REPO = "${DOCKERHUB_USERNAME}"
        
        // Service Names
        SERVICES = 'config-server eureka-server gateway auth-service user-service job-service notification-service file-storage'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from Git...'
                checkout scm
            }
        }
        
        // Skipping Maven Build in CI
        // stage('Build Maven Projects') { ... }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo 'Installing kubectl...'
                    // Download kubectl binary specific to our environment (Linux AMD64)
                    sh 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"'
                    sh 'chmod +x kubectl'
                    
                    echo 'Deploying changes...'
                    
                    // Apply common resources explicitly to microservices namespace where applicable
                    sh './kubectl apply -f kubernetes/namespace.yaml'
                    // ConfigMaps and Secrets should be in microservices namespace
                    sh './kubectl apply -f kubernetes/configmaps/ -n microservices'
                    sh './kubectl apply -f kubernetes/secrets/db-secrets.yaml -n microservices || true'
                    
                    // Deploy Infrastructure and Services
                    sh './kubectl apply -f kubernetes/infrastructure/ -n microservices || true'
                    sh './kubectl apply -f kubernetes/services/ -n microservices || true'
                    
                    def services = env.SERVICES.split(' ')
                    for (def service : services) {
                        def yamlFile = "kubernetes/deployments/${service}.yaml"
                        // Apply to microservices namespace explicitly
                        sh "./kubectl apply -f ${yamlFile} -n microservices"
                    }
                    
                    echo 'Waiting for rollout...'
                    sh './kubectl wait --for=condition=available deployment --all -n microservices --timeout=300s || true'
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up...'
        }
    }
}

