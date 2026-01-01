import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*

println "START_VERBOSE_RESTORE"
def instance = Jenkins.getInstance()

def jn = "microservices-pipeline"
def job = instance.getItem(jn)
if (job) {
    println "JOB_ALREADY_EXISTS_REMOVING"
    job.delete()
}

job = instance.createProject(WorkflowJob.class, jn)
println "JOB_CREATED_NEW"

def repo = "https://github.com/hushhrf/microservices-ci-cd.git"
def scm = new GitSCM(repo)
scm.branches = [new BranchSpec("*/main")]
job.definition = new CpsScmFlowDefinition(scm, "Jenkinsfile")
job.save()
println "JOB_SAVED"

println "LISTING_ALL_JOBS:"
instance.getAllItems(WorkflowJob.class).each { println "FOUND_JOB: ${it.name}" }

if (instance.getItem(jn)) {
    println "VERIFICATION_SUCCESS"
    def b = instance.getItem(jn).scheduleBuild2(0)
    if (b) { println "BUILD_TRIGGERED" }
} else {
    println "VERIFICATION_FAILURE"
}

instance.save()
println "RESTORE_END"