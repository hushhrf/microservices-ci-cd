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
    image: hushhrf/jenkins-agent:latest
    imagePullPolicy: Always
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }
    
    environment {
        // AWS Configuration
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER_NAME = 'microservices-cluster'
        
        // Docker Configuration - Using Credentials Binding for security
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
        
        stage('Build Maven Projects') {
            parallel {
                stage('Build Config Server') { steps { dir('config-server') { sh 'mvn clean package -DskipTests' } } }
                stage('Build Eureka Server') { steps { dir('eureka-server') { sh 'mvn clean package -DskipTests' } } }
                stage('Build Gateway') { steps { dir('gateway') { sh 'mvn clean package -DskipTests' } } }
                stage('Build Auth Service') { steps { dir('auth-service') { sh 'mvn clean package -DskipTests' } } }
                stage('Build User Service') { steps { dir('user-service') { sh 'mvn clean package -DskipTests' } } }
                stage('Build Job Service') { steps { dir('job-service') { sh 'mvn clean package -DskipTests' } } }
                stage('Build Notification Service') { steps { dir('notification-service') { sh 'mvn clean package -DskipTests' } } }
                stage('Build File Storage') { steps { dir('file-storage') { sh 'mvn clean package -DskipTests' } } }
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                        
                        def services = env.SERVICES.split(' ')
                        for (def service : services) {
                            echo "Building and Pushing Docker image for ${service}..."
                            dir(service) {
                                sh """
                                    docker build -t ${DOCKERHUB_REPO}/${service}:latest .
                                    docker tag ${DOCKERHUB_REPO}/${service}:latest ${DOCKERHUB_REPO}/${service}:${BUILD_NUMBER}
                                    docker push ${DOCKERHUB_REPO}/${service}:latest
                                    docker push ${DOCKERHUB_REPO}/${service}:${BUILD_NUMBER}
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                anyOf { branch 'main'; branch 'master' }
            }
            steps {
                dir('terraform') {
                    // Initialize if needed, or assume infrastructure is ready
                    sh 'terraform init'
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo 'Configuring kubectl...'
                    sh "aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}"
                    
                    echo 'Deploying changes...'
                    
                    // Apply common resources first
                    sh 'kubectl apply -f kubernetes/namespace.yaml'
                    sh 'kubectl apply -f kubernetes/configmaps/'
                    sh 'kubectl apply -f kubernetes/secrets/db-secrets.yaml || true'
                    
                    def services = env.SERVICES.split(' ')
                    for (def service : services) {
                        def yamlFile = "kubernetes/deployments/${service}.yaml"
                        // Dynamic image tag update
                        sh "sed -i 's|image: .*|image: ${DOCKERHUB_REPO}/${service}:${BUILD_NUMBER}|' ${yamlFile}"
                        sh "kubectl apply -f ${yamlFile}"
                        // Reset file for git cleanliness (optional)
                        sh "git checkout ${yamlFile}"
                    }
                    
                    echo 'Waiting for rollout...'
                    sh 'kubectl wait --for=condition=available deployment --all -n microservices --timeout=300s || true'
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

