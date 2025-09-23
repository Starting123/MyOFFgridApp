buildscript {
    extra.apply {
        set("kotlin_version", "1.9.10")  // Updated Kotlin version
    }
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        val kotlinVersion = rootProject.extra.get("kotlin_version") as String
        classpath("com.android.tools.build:gradle:8.1.1")  // Updated Gradle plugin version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
