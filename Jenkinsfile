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
    volumeMounts:
    - name: workspace
      mountPath: /home/jenkins/agent
  - name: maven
    image: maven:3.8.6-openjdk-18
    command:
    - cat
    tty: true
    volumeMounts:
    - name: workspace
      mountPath: /home/jenkins/agent
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - sleep
    args:
    - 9999999
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker
    - name: workspace
      mountPath: /home/jenkins/agent
  - name: kubectl
    image: alpine/k8s:1.29.2
    command:
    - cat
    tty: true
    volumeMounts:
    - name: workspace
      mountPath: /home/jenkins/agent
  volumes:
  - name: kaniko-secret
    secret:
      secretName: dockerhub-credentials
      items:
      - key: .dockerconfigjson
        path: config.json
  - name: workspace
    emptyDir: {}
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
        
        stage('Build & Deploy Microservices') {
            steps {
                script {
                    def services = env.SERVICES.split(' ')
                    for (def service : services) {
                        stage("Service: ${service}") {
                            container('maven') {
                                echo "Building ${service}..."
                                sh "cd ${service} && mvn clean package -DskipTests"
                            }
                            
                            container('kaniko') {
                                echo "Building and Pushing Docker image for ${service}..."
                                sh "/kaniko/executor --context ./${service} --dockerfile ./${service}/Dockerfile --destination ${DOCKERHUB_REPO}/${service}:latest"
                            }
                            
                            container('kubectl') {
                                echo "Deploying ${service}..."
                                sh "kubectl apply -f kubernetes/deployments/${service}.yaml -n microservices"
                                sh "kubectl rollout restart deployment/${service} -n microservices"
                            }
                        }
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

