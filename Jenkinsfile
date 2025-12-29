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
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ['cat']
    tty: true
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
        
        // Skipping Maven Build in CI to save time/resources (Option A)
        // stage('Build Maven Projects') { ... }
        
        // Skipping Docker Build & Push (Built locally)
        /* 
        stage('Docker Build & Push') {
            steps {
                script {
                   // ... (Commented out for Option A)
                }
            }
        }
        */
        
        // Skipping Terraform Plan to avoid needing Terraform image
        /*
        stage('Terraform Plan') {
            steps {
               // ...
            }
        }
        */
        
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    script {
                        echo 'Configuring kubectl...'
                        // Jenkins ServiceAccount has ClusterAdmin permissions (verified in jenkins-sa.yaml)
                        // It injects credentials automatically, so we DO NOT need aws-cli or update-kubeconfig.
                        // We rely on standard in-cluster Kubernetes configuration.
                        
                        echo 'Deploying changes...'
                        
                        // Apply common resources explicitly to microservices namespace where applicable
                        sh 'kubectl apply -f kubernetes/namespace.yaml'
                        // ConfigMaps and Secrets should be in microservices namespace
                        sh 'kubectl apply -f kubernetes/configmaps/ -n microservices'
                        sh 'kubectl apply -f kubernetes/secrets/db-secrets.yaml -n microservices || true'
                        
                        def services = env.SERVICES.split(' ')
                        for (def service : services) {
                            def yamlFile = "kubernetes/deployments/${service}.yaml"
                            // Apply to microservices namespace explicitly
                            sh "kubectl apply -f ${yamlFile} -n microservices"
                        }
                        
                        echo 'Waiting for rollout...'
                        sh 'kubectl wait --for=condition=available deployment --all -n microservices --timeout=300s || true'
                    }
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

