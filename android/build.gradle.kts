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
    afterEvaluate {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.apply {
            // 針對 inappwebview 的特殊修正
            if (project.name.contains("flutter_inappwebview")) {
                compileSdkVersion(34)
                tasks.withType<JavaCompile>().configureEach {
                    val sdkPath = android.sdkDirectory.absolutePath
                    val androidJar = file("$sdkPath/platforms/android-34/android.jar")
                    if (androidJar.exists()) {
                        println("Fixing inappwebview: injecting bootstrapClasspath from $androidJar")
                        options.bootstrapClasspath = project.files(androidJar)
                    }
                }
            } else {
                // 其他插件維持 SDK 35/36
                if (compileSdkVersion == null || (compileSdkVersion?.startsWith("android-") == true && compileSdkVersion!!.substringAfter("android-").toInt() < 36)) {
                    compileSdkVersion(36)
                }
            }
            
            // 自動修復缺失的 namespace
            if (namespace == null) {
                namespace = "io.legado.reader.${project.name.replace("-", ".")}"
            }
            
            // 專門修復 isar_flutter_libs 3.1.0+1 在 AGP 8.0+ 下的 Manifest 衝突
            if (project.name == "isar_flutter_libs") {
                namespace = "dev.isar.isar_flutter_libs"
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=\"dev.isar.isar_flutter_libs\"")) {
                        println("Fixing isar_flutter_libs manifest: removing package attribute")
                        manifestFile.writeText(content.replace("package=\"dev.isar.isar_flutter_libs\"", ""))
                    }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

gradle.projectsEvaluated {
    allprojects {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
