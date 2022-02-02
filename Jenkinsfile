
pipeline {
    agent any
    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5'))
    }
    environment {
            BRANCH_NAME_NORMALIZED = sh(
                script: "echo '${BRANCH_NAME}' | sed s#/#-#g",
                returnStdout: true
            ).trim()
            DOCKER_TAG_VERSION = sh(
                script: "echo '${POM_VERSION}' | sed 's/SNAPSHOT/$BRANCH_NAME_NORMALIZED/'",
                returnStdout: true
            ).trim()
        }
        stages {

                stage('Log variables') {
                    steps {
                        echo "Git branch: $BRANCH_NAME"
                        echo "Git branch (normalized): $BRANCH_NAME_NORMALIZED"
                        echo "Git commit: $GIT_COMMIT"
                        echo "Git commit (abbreviated): $GIT_COMMIT_SHORT"
                        echo "Docker tag w/ version number: $DOCKER_TAG_VERSION"
                          }
                    }
                }
            }