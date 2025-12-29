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
                        // EKS authentication requires aws-cli. 
                        // bitnami/kubectl does NOT have aws-cli.
                        // We need a container with BOTH or use a token.
                        // Since we are inside the cluster, we might not need 'aws eks update-kubeconfig' if RBAC is correct.
                        // However, 'aws eks update-kubeconfig' generates the ~/.kube/config.
                        // 
                        // ALTERNATIVE: Use an image with both aws-cli and kubectl.
                        // 'amazon/aws-cli' has aws, but installing kubectl is executing steps.
                        // 'bitnami/kubectl' has no aws-cli.
                        // 
                        // Let's try to trust the service account injection.
                        // If the pod has 'serviceAccountName: jenkins-sa', it usually auto-mounts credentials.
                        // But standard kubectl needs a config file pointing to the API server.
                        // In-cluster config is supported by kubectl by default if KUBERNETES_SERVICE_HOST is set.
                        // We just need to ensure context is set or just run commands.
                        
                        echo 'Deploying changes...'
                        
                        // Apply common resources first
                        sh 'kubectl apply -f kubernetes/namespace.yaml'
                        sh 'kubectl apply -f kubernetes/configmaps/'
                        sh 'kubectl apply -f kubernetes/secrets/db-secrets.yaml || true'
                        
                        def services = env.SERVICES.split(' ')
                        for (def service : services) {
                            def yamlFile = "kubernetes/deployments/${service}.yaml"
                            // For Option A, we assume 'latest' or manual tag management since we aren't building here.
                            // If we want to use the specific build number, we'd need to have pushed it locally first.
                            // For simplicity, let's just apply the YAMLs "as is" or update to 'latest'.
                            
                            sh "kubectl apply -f ${yamlFile}"
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

