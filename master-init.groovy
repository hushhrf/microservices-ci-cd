import jenkins.model.*
import hudson.model.*
import jenkins.security.*
import hudson.security.*

println "--- MASTER INITIALIZATION START ---"
def instance = Jenkins.getInstance()

// 1. Create Admin User (Always safe)
println "Configuring Admin User..."
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin")
instance.setSecurityRealm(hudsonRealm)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
println "ADMIN_USER_CREATED"

// 2. Install Plugins
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()
uc.updateAllSites()

def requiredPlugins = ["kubernetes", "git", "workflow-aggregator", "docker-workflow", "credentials-binding"]
def installedAny = false

requiredPlugins.each { name ->
    if (pm.getPlugin(name) == null) {
        println "Installing plugin: ${name}"
        def plugin = uc.getById("default").getPlugin(name)
        if (plugin) {
            plugin.deploy()
            installedAny = true
        }
    }
}

if (installedAny) {
    println "PLUGINS_INSTALLING: Restarting Jenkins is recommended after plugins download."
    // We don't force restart here, but we can't continue with Cloud/Job config if classes are missing
}

// 3. Deferred Config (Use String-based execution to avoid compile-time import errors)
def scriptsDir = new File(instance.getRootDir(), "init.groovy.d")
def deferredScript = new File(scriptsDir, "deferred-config.groovy")

deferredScript.text = """
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import org.csanchez.jenkins.plugins.kubernetes.*

println "--- DEFERRED CONFIGURATION START ---"
def inst = Jenkins.getInstance()

try {
    // A. DockerHub Credentials
    def domain = Domain.global()
    def store = inst.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
    def creds = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL, "dockerhub-credentials", "Docker Hub", "hushhrf", "DOCKER_TOKEN_PLACEHOLDER"
    )
    def existing = store.getCredentials(domain).find { it.id == "dockerhub-credentials" }
    if (existing) { store.removeCredentials(domain, existing) }
    store.addCredentials(domain, creds)
    println "CREDENTIALS_RESTORED"

    // B. K8s Cloud
    def k8s = new KubernetesCloud("kubernetes")
    k8s.setServerUrl("https://kubernetes.default.svc.cluster.local")
    k8s.setNamespace("jenkins")
    k8s.setJenkinsUrl("http://jenkins.jenkins.svc.cluster.local:8080/jenkins")
    k8s.setJenkinsTunnel("jenkins.jenkins.svc.cluster.local:50000")
    k8s.setSkipTlsVerify(true)
    inst.clouds.clear()
    inst.clouds.add(k8s)
    println "CLOUD_RESTORED"

    // C. Job
    def job = inst.getItem("microservices-pipeline")
    if (!job) {
        job = inst.createProject(WorkflowJob.class, "microservices-pipeline")
    }
    def repo = "https://github.com/hushhrf/microservices-ci-cd.git"
    job.definition = new CpsScmFlowDefinition(new GitSCM(repo), "Jenkinsfile")
    job.save()
    println "JOB_RESTORED"

    inst.save()
    println "--- DEFERRED CONFIGURATION COMPLETE ---"
} catch (Exception e) {
    println "DEFERRED_INIT_ERROR: " + e.message
}
"""

instance.save()
println "--- MASTER INITIALIZATION COMPLETE (STAGE 1) ---"
