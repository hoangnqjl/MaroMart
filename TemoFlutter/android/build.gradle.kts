allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

subprojects {
    // Only redirect the 'app' project to ensure APK is found by Flutter tool
    // Plugins remain in their own local build folders to avoid cross-drive root errors
    if (project.name == "app") {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
    // Fix: "this and base files have different roots" error when project is on D: and pub cache on C:
    tasks.withType<Test> {
        enabled = false
    }
    tasks.whenTaskAdded {
        if (name.contains("UnitTest")) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
