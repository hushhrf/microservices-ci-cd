Jenkins.instance.reload()
println "RELOAD_COMPLETE"
def job = Jenkins.instance.getItem("microservices-pipeline")
if (job) {
    println "JOB_FOUND_AFTER_RELOAD"
    job.scheduleBuild2(0)
    println "BUILD_TRIGGERED"
}