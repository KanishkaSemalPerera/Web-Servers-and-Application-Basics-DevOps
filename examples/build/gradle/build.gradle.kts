// Gradle (Kotlin DSL) equivalent of the Maven pom.xml
// Build:   ./gradlew clean build      -> build/libs/demo-app-1.0.0.jar
// Test:    ./gradlew test
// Publish: ./gradlew publish          -> uploads to Nexus
// Always use the wrapper (./gradlew) so everyone uses the same Gradle version.

plugins {
    java
    `maven-publish`
}

group = "com.example"
version = "1.0.0"

java {
    toolchain { languageVersion.set(JavaLanguageVersion.of(21)) }
}

repositories {
    // In companies, point this at Nexus/Artifactory instead of the internet
    // maven { url = uri("http://nexus.example.local:8081/repository/maven-public/") }
    mavenCentral()
}

dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.2")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.test {
    useJUnitPlatform()
}

publishing {
    publications {
        create<MavenPublication>("mavenJava") { from(components["java"]) }
    }
    repositories {
        maven {
            name = "nexus"
            url = uri("http://nexus.example.local:8081/repository/maven-releases/")
            isAllowInsecureProtocol = true      // lab only - use https in real life
            credentials {
                username = System.getenv("NEXUS_USER")
                password = System.getenv("NEXUS_PASSWORD")
            }
        }
    }
}
