import jenkins.model.*
import hudson.model.*

println "--- DIAGNOSTICS START ---"
def instance = Jenkins.getInstance()

println "ACTIVE_PLUGINS:"
instance.pluginManager.plugins.each { if (it.isActive()) println "PLUGIN: ${it.shortName}:${it.version}" }

println "CURRENT_ITEMS:"
instance.getAllItems().each { println "ITEM: ${it.name} (${it.class.name})" }

try {
    println "ATTEMPTING_FREESTYLE_CREATION"
    def dummy = instance.createProject(FreeStyleProject.class, "diag-job-simple")
    dummy.save()
    println "FREESTYLE_CREATED: ${instance.getItem('diag-job-simple') != null}"
} catch (e) {
    println "FREESTYLE_ERROR: ${e.message}"
    e.printStackTrace()
}

println "--- DIAGNOSTICS END ---"