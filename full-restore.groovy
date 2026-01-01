import jenkins.model.*
import hudson.model.*

println "--- FULL RESTORE START ---"
def instance = jenkins.model.Jenkins.getInstance()

def pm = instance.getPluginManager()

// Check for required plugins directly
def credentialsPlugin = pm.getPlugin("credentials")
def kubernetesPlugin = pm.getPlugin("kubernetes")
def gitPlugin = pm.getPlugin("git")
def workflowJobPlugin = pm.getPlugin("workflow-job")

if (credentialsPlugin == null || !credentialsPlugin.isActive() ||
    kubernetesPlugin == null || !kubernetesPlugin.isActive() ||
    gitPlugin == null || !gitPlugin.isActive() ||
    workflowJobPlugin == null || !workflowJobPlugin.isActive()) {
    println "WAITING_FOR_PLUGINS: Plugins not yet fully active. Required: credentials, kubernetes, git, workflow-job"
    return
}

try {
    // 1. Credentials
    println "Configuring Credentials..."
    def domain = com.cloudbees.plugins.credentials.domains.Domain.global()
    def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
    
    def creds = new com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl(
        com.cloudbees.plugins.credentials.CredentialsScope.GLOBAL, 
        "dockerhub-credentials", 
        "Docker Hub",
        "hushhrf", 
        "DOCKER_TOKEN_PLACEHOLDER"
    )
    
    def existing = store.getCredentials(domain).find { it.id == "dockerhub-credentials" }
    if (existing) { store.removeCredentials(domain, existing) }
    store.addCredentials(domain, creds)
    println "CREDENTIALS_RESTORED"

    // 2. K8s Cloud
    println "Configuring K8s Cloud..."
    def k8s = new org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud("kubernetes")
    k8s.setServerUrl("https://kubernetes.default.svc.cluster.local")
    k8s.setNamespace("jenkins")
    k8s.setJenkinsUrl("http://jenkins.jenkins.svc.cluster.local:8080/jenkins")
    instance.clouds.clear()
    instance.clouds.add(k8s)
    println "CLOUD_RESTORED"

    // 3. Job
    println "Configuring Job..."
    def jn = "microservices-pipeline"
    def job = instance.getItem(jn)
    if (!job) {
        job = instance.createProject(org.jenkinsci.plugins.workflow.job.WorkflowJob.class, jn)
        println "JOB_CREATED"
    }
    
    def scm = new hudson.plugins.git.GitSCM("https://github.com/hushhrf/microservices-ci-cd.git")
    scm.branches = [new hudson.plugins.git.BranchSpec("*/main")]
    job.definition = new org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition(scm, "Jenkinsfile")
    job.save()
    println "JOB_CONFIGURED"

    instance.save()
    println "--- FULL RESTORE COMPLETE ---"
} catch (Exception e) {
    println "RESTORE_ERROR: ${e.message}"
}