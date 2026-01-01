import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import org.csanchez.jenkins.plugins.kubernetes.*

println "Starting internal configuration..."
def instance = Jenkins.getInstance()

// 1. DockerHub Credentials
def domain = Domain.global()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
def usernamePassword = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "dockerhub-credentials",
    "Docker Hub Credentials",
    "hushhrf",
    "DOCKER_TOKEN_PLACEHOLDER"
)
def existingCreds = store.getCredentials(domain).find { it.id == "dockerhub-credentials" }
if (existingCreds) { store.removeCredentials(domain, existingCreds) }
store.addCredentials(domain, usernamePassword)
println "DockerHub credentials restored."

// 2. Kubernetes Cloud
def k8sName = "kubernetes"
def existingCloud = instance.clouds.getByName(k8sName)
if (existingCloud) { instance.clouds.remove(existingCloud) }
def k8s = new KubernetesCloud(k8sName)
k8s.setServerUrl("https://kubernetes.default.svc.cluster.local")
k8s.setNamespace("jenkins")
k8s.setJenkinsUrl("http://jenkins.jenkins.svc.cluster.local:8080/jenkins")
instance.clouds.add(k8s)
println "Kubernetes cloud restored."

// 3. Pipeline Job
def jobName = "microservices-pipeline"
def job = instance.getItem(jobName)
if (job == null) {
    job = instance.createProject(WorkflowJob.class, jobName)
}
def repoUrl = "https://github.com/hushhrf/microservices-ci-cd.git"
def branchSpec = [new BranchSpec("*/main")]
def scm = new GitSCM(repoUrl)
scm.branches = branchSpec
job.definition = new CpsScmFlowDefinition(scm, "Jenkinsfile")
job.save()
println "Job $jobName restored."

instance.save()
println "RESTORE_COMPLETE"
