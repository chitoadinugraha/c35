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
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        val ext = extensions.findByName("android") ?: return@afterEvaluate
        try {
            ext.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType).invoke(ext, 36)
        } catch (_: Exception) {
            try {
                ext.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType).invoke(ext, 36)
            } catch (_: Exception) {}
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
