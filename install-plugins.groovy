import jenkins.model.*
import hudson.model.*

def plugins = ["workflow-aggregator", "kubernetes", "git", "docker-workflow", "workflow-job", "workflow-cps", "credentials"]
def instance = jenkins.model.Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

println "--- PLUGIN INSTALLATION START ---"

// Refresh update center
println "Refreshing Update Center..."
uc.updateAllSites()

plugins.each { name ->
    if (!pm.getPlugin(name)) {
        println "INSTALLING: ${name}"
        def plugin = uc.getPlugin(name)
        if (plugin) {
            def deployment = plugin.deploy(true)
            deployment.get()
            println "DEPLOYED: ${name}"
        } else {
            println "ERROR: Plugin ${name} not found in update center after refresh"
        }
    } else {
        println "ALREADY_INSTALLED: ${name}"
    }
}
println "--- PLUGIN INSTALLATION REQUESTED ---"
instance.save()