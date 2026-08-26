allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io")
        // Fallback mirror for networks where Google/Maven Central are unreachable.
        maven("https://en-mirror.ir")
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    configurations.all {
        resolutionStrategy.dependencySubstitution {
            substitute(module("com.github.Dimezis:BlurView"))
                .using(module("com.github.Dimezis:BlurView:version-2.0.3"))
                .because("Tag '2.0.3' does not exist on JitPack; the published tag is 'version-2.0.3'")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
