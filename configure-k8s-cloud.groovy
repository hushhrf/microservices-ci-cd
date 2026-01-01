import jenkins.model.*
import org.csanchez.jenkins.plugins.kubernetes.*
import jenkins.model.Jenkins

def cloudName = "kubernetes"
def existingCloud = Jenkins.instance.clouds.getByName(cloudName)

if (existingCloud != null) {
    println "Kubernetes cloud '${cloudName}' already exists."
} else {
    println "Creating Kubernetes cloud '${cloudName}'..."
    
    // In-cluster configuration
    def k8s = new KubernetesCloud(cloudName)
    k8s.setServerUrl("https://kubernetes.default.svc")
    k8s.setSkipTlsVerify(true) // For internal cluster comms
    k8s.setNamespace("jenkins")
    k8s.setJenkinsUrl("http://jenkins.jenkins.svc.cluster.local:8080")
    k8s.setJenkinsTunnel("jenkins.jenkins.svc.cluster.local:50000")
    
    // Default pod retention (optional)
    k8s.setRetentionTimeout(5)
    
    Jenkins.instance.clouds.add(k8s)
    Jenkins.instance.save()
    println "Kubernetes cloud '${cloudName}' created successfully."
}
