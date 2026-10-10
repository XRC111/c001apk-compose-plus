// 国内镜像开关：本地开发默认启用（下载快），CI 上设置 USE_CN_MIRROR=false 走官方源
val useCnMirror: Boolean =
    System.getenv("USE_CN_MIRROR")?.toBooleanStrictOrNull() ?: true

pluginManagement {
    repositories {
        if (useCnMirror) {
            maven("https://maven.aliyun.com/repository/gradle-plugin")
            maven("https://maven.aliyun.com/repository/google")
            maven("https://maven.aliyun.com/repository/public")
        }
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
        if (useCnMirror) {
            maven("https://maven.aliyun.com/repository/google")
            maven("https://maven.aliyun.com/repository/public")
        }
        google()
        mavenCentral()
        maven ("https://jitpack.io")
        maven("https://oss.sonatype.org/content/repositories/public")
        gradlePluginPortal()
    }
}

rootProject.name = "c001apk-compose"
include(":app", ":mojito", ":SketchImageViewLoader", ":media-support")
