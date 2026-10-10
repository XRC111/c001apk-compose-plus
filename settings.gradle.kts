pluginManagement {
    repositories {
        maven("https://maven.aliyun.com/repository/gradle-plugin")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/public")
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

gradle.settingsEvaluated {
    val currentBranch = providers.exec {
        commandLine("git", "rev-parse", "--abbrev-ref", "HEAD")
    }.standardOutput.asText.map { it.trim() }.get()
    logger.lifecycle("当前 Git 分支: $currentBranch。请确认分支正确！若需切换：git checkout <branch>")
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/public")
        google()
        mavenCentral()
        maven ("https://jitpack.io")
        maven("https://oss.sonatype.org/content/repositories/public")
        gradlePluginPortal()
    }
}

rootProject.name = "c001apk-compose"
include(":app", ":mojito", ":SketchImageViewLoader", ":media-support")
