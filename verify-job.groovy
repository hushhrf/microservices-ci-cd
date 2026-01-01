def jn = "microservices-pipeline"
def job = Jenkins.instance.getItem(jn)
if (job) {
    println "JOB_FOUND"
    println "BUILD_COUNT: ${job.builds.size()}"
    if (job.lastBuild) {
        println "LAST_BUILD_#${job.lastBuild.number}: ${job.lastBuild.result} (Building: ${job.lastBuild.isBuilding()})"
        if (job.lastBuild.isBuilding()) {
            println "BUILD_LOG_TAIL:"
            println job.lastBuild.getLog(20).join("\n")
        }
    }
} else {
    println "JOB_NOT_FOUND"
}