import hudson.plugins.git.GitTool
import jenkins.model.Jenkins

def inst = Jenkins.get()
def desc = inst.getDescriptor("hudson.plugins.git.GitTool")
def gitHome = "/usr/bin/git"
def names = ["Default", "git", "Git"] as LinkedHashSet
def existing = (desc.installations ?: []) as List
def byName = existing.collectEntries { [(it.name): it] }

names.each { n ->
  byName[n] = new GitTool(n, gitHome, [])
}
desc.installations = byName.values() as GitTool[]
desc.save()
println "Configured Git installations: ${desc.installations*.name} -> ${gitHome}"
