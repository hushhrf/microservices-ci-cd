def job = Jenkins.instance.getItem("microservices-pipeline")
if (job) {
    println "JOB_FOUND"
    println "LAST_BUILD: ${job.lastBuild}"
    println "IS_BUILDING: ${job.isBuilding()}"
    println "IN_QUEUE: ${job.isInQueue()}"
} else {
    println "JOB_NOT_FOUND"
}
def queue = Jenkins.instance.queue
println "QUEUE_ITEMS: ${queue.items.length}"
queue.items.each { println "QUEUE_ITEM: ${it.task.name}" }
