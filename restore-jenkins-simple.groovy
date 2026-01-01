import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.*
import org.csanchez.jenkins.plugins.kubernetes.*

def instance = Jenkins.getInstance()

// 1. DockerHub
def domain = Domain.global()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
def usernamePassword = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "dockerhub-credentials",
    "Docker Hub Credentials",
    "hushhrf",
    "DOCKER_TOKEN_PLACEHOLDER"
)
def eC = store.getCredentials(domain).find { it.id == "dockerhub-credentials" }
if (eC) { store.removeCredentials(domain, eC) }
store.addCredentials(domain, usernamePassword)

// 2. K8s Cloud
def kn = "kubernetes"
def eK = instance.clouds.getByName(kn)
if (eK) { instance.clouds.remove(eK) }
def k8s = new KubernetesCloud(kn)
k8s.setServerUrl("https://kubernetes.default.svc.cluster.local")
k8s.setNamespace("jenkins")
k8s.setJenkinsUrl("http://jenkins.jenkins.svc.cluster.local:8080/jenkins")
instance.clouds.add(k8s)

// 3. Job
def jn = "microservices-pipeline"
def job = instance.getItem(jn)
if (job == null) { job = instance.createProject(WorkflowJob, jn) }
def repo = "https://github.com/hushhrf/microservices-ci-cd.git"
def scm = new GitSCM(repo)
scm.branches = [new BranchSpec("*/main")]
job.definition = new CpsScmFlowDefinition(scm, "Jenkinsfile")
job.save()

instance.save()
println "RESTORE_SUCCESSFUL"
