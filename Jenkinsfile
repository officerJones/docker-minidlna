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
        PROJECT_NAME="minidlna"
        TEST_TAG="${DOCKER_HUB_USER}/${PROJECT_NAME}:test"
        def IMAGE_VERSION=readFile "version"
        RELEASE_TAG="${DOCKER_HUB_USER}/${PROJECT_NAME}:${IMAGE_VERSION}"
        LATEST_TAG="${DOCKER_HUB_USER}/${PROJECT_NAME}:latest"
        TAG_NAME = sh(returnStdout: true, script: 'git tag -l --points-at HEAD').trim()
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
        stage('Tests') {
            environment {
                // Variables used by GOSS framework
                GOSS_FILES_STRATEGY="cp"
                GOSS_OPTS="--format junit"
                // Overwrite environment variables in docker-compose.yml
                VERSION_TAG="test"
            }
            steps {
                // Run dcgoss with junit output
                sh """
                    mkdir -p testresults
                    dcgoss run minidlna > testresults/dcgoss_testresults.xml
                """
                // sed -n '/<?xml/,/<\\/testsuite/p' testresults/dcgoss_testresults.txt > testresults/dcgoss_testresults.xml
            }
        }
        stage('Push to Docker Hub') {
            // Only push on master branch when release tag is present
            when {
                    branch 'master'
                    tag 'release-*'
            }
                steps {
                    withDockerRegistry([ credentialsId: "docker_hub_credentials", url: ""]) {
                        sh """
                            echo 'Tagging ${TEST_TAG} with ${RELEASE_TAG}'
                            docker tag ${TEST_TAG} ${RELEASE_TAG}
                            docker tag ${TEST_TAG} ${LATEST_TAG}
                            echo 'Pushing images'
                            docker push ${RELEASE_TAG}
                            docker push ${LATEST_TAG}
                        """
                    }
                }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'testresults/*'
            junit 'testresults/*.xml'
            // Try to delete container & image and make sure it exits fine
            sh "docker rm -f ${PROJECT_NAME} || true"
            sh "docker image rm -f ${TEST_TAG} || true"
        }
        success {
            setBuildStatus("Build succeeded", "SUCCESS");
        }
        failure {
            setBuildStatus("Build failed", "FAILURE");
        }
    }
}
