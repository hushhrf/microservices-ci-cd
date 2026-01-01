def job = Jenkins.instance.getItem("microservices-pipeline")
if (job) {
    job.scheduleBuild2(0)
    println "BUILD_TRIGGERED"
} else {
    println "JOB_NOT_FOUND"
}
