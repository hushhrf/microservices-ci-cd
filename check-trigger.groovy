def job = Jenkins.instance.getItem("microservices-pipeline")
if (job) {
    println "JOB_FOUND"
    def b = job.scheduleBuild2(0)
    if (b) { println "BUILD_TRIGGERED_SUCCESS" } else { println "BUILD_TRIGGERED_FAIL" }
    println "LAST_BUILD: ${job.lastBuild}"
} else {
    println "JOB_NOT_FOUND"
}