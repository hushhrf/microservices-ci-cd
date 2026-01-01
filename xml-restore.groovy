def jn = "microservices-pipeline"
def xml = """<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/hushhrf/microservices-ci-cd.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec><name>*/main</name></hudson.plugins.git.BranchSpec>
      </branches>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
  </definition>
</flow-definition>"""

def instance = Jenkins.getInstance()
if (instance.getItem(jn)) { instance.getItem(jn).delete() }
instance.createProjectFromXML(jn, new java.io.ByteArrayInputStream(xml.getBytes("UTF-8")))
println "JOB_CREATED_VIA_XML_STRING"
instance.getItem(jn).scheduleBuild2(0)
println "BUILD_TRIGGERED"