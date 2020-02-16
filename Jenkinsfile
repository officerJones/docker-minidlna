void setBuildStatus(String message, String state) {
  step([
      $class: "GitHubCommitStatusSetter",
      reposSource: [$class: "ManuallyEnteredRepositorySource", url: "https://github.com/officerJones/docker-minidlna"],
      contextSource: [$class: "ManuallyEnteredCommitContextSource", context: "ci/jenkins/build-status"],
      errorHandlers: [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
      statusResultSource: [ $class: "ConditionalStatusResultSource", results: [[$class: "AnyBuildResult", message: message, state: state]] ]
  ]);
}

pipeline {
    agent {
        label 'docker-slave'
    }
    environment {
        HOME="${env.WORKSPACE}"
        PATH="$PATH:${HOME}/.local/bin"
        // DOCKER_HUB_USER is configured as global variable in Jenkins
        DOCKER_HUB_PASS=credentials('docker_hub_password')
        NAME_TAG="minidlna"
        TEST_TAG="${NAME_TAG}:test"
        BUILD_TAG="${DOCKER_HUB_USER}/${NAME_TAG}"
        def IMAGE_VERSION=readFile "version"
    }
    stages {
        stage('Dockerfile syntax check') {
            steps {
                // Check the syntax with dockerlint
                sh 'dockerlint -f ${HOME}/Dockerfile'
            }
        }
        stage('docker-compose syntax check') {
            steps {
                // Check the syntax with dockerlint
                sh 'docker-compose config'
            }
        }
        stage('Build') {
            steps {
                // Build the image with a test tag
                sh 'docker build --tag ${TEST_TAG} .'
            }
        }
        stage('Push to Docker Hub') {
            when{
                branch 'master'
            }
                steps {
                    script {
                        // Tag test image with production tag & push
                        sh """
                            echo 'Tagging with version ${IMAGE_VERSION}'
                            docker tag ${TEST_TAG} ${BUILD_TAG}:${IMAGE_VERSION}
                            echo '${DOCKER_HUB_PASS}' | docker login --username ${DOCKER_HUB_USER} --password-stdin
                            docker push ${BUILD_TAG}:${IMAGE_VERSION}
                            docker logout
                        """
                    }
                }
        }
/*
         stage('Push to Github Packages') {
            when{
                branch 'master'
            }
                steps {
                    script {
                        // Tag test image with production tag & push
                        sh """

                        """
                    }
                }
        }
*/
    }
    post {
        success {
            sh "docker image rm ${TEST_TAG}"
            setBuildStatus("Build succeeded", "SUCCESS");
        }
        failure {
            setBuildStatus("Build failed", "FAILURE");
        }
    }
}
