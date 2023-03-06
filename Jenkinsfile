@Library('vega-shared-library') _

def commitHash = 'UNKNOWN'

pipeline {
    agent { label 'general' }
    options {
        skipDefaultCheckout true
        parallelsAlwaysFailFast()
    }
    environment {
        GO111MODULE = 'on'
        SLACK_MESSAGE = "Specs-Internal CI » <${RUN_DISPLAY_URL}|Jenkins ${BRANCH_NAME} Job>${ env.CHANGE_URL ? " » <${CHANGE_URL}|GitHub PR #${CHANGE_ID}>" : '' }"
    }

    stages {
        stage('setup') {
            steps {
                sh 'printenv'
                echo "${params}"
            }
        }
        stage('Git clone') {
            parallel {
                stage('specs-internal') {
                    steps {
                        retry(3) {
                            dir('specs-internal') {
                                checkout scm
                                script {
                                    commitHash = getCommitHash()
                                }
                            }
                        }
                    }
                }
                stage('vega core') {
                    steps {
                        retry(3) {
                            dir('vega') {
                                git branch: 'develop', credentialsId: 'vega-ci-bot', url: 'git@github.com:vegaprotocol/vega.git'
                            }
                        }
                    }
                }
            }
        }

        stage('Run checks') {
            parallel {
                stage('lint: yaml') {
                    steps {
                        retry(3) {
                            dir('specs-internal') {
                                sh 'yamllint -s -d "{extends: default, rules: {line-length: {max: 160}}}" .'
                            }
                        }
                    }
                }
                stage('approbation') {
                    when {
                        anyOf {
                            branch 'develop'
                            branch 'main'
                            branch 'master'
                        }
                    }
                    parallel {
                        stage('Core') {
                            steps {
                                runApprobation ignoreFailure: !isPRBuild(),
                                    specsInternal: commitHash,
                                    type: 'core',
                            }
                        }
                        stage('Frontend') {
                            steps {
                                runApprobation ignoreFailure: !isPRBuild(),
                                    specsInternal: commitHash,
                                    type: 'frontend',
                            }
                        }
                    }
                }
            }
        }
    }
    post {
        // success {
        //     retry(3) {
        //         slackSend(channel: "#protocol-design-notify", color: "good", message: ":white_check_mark: ${SLACK_MESSAGE}")
        //     }
        // }
        unsuccessful {
            retry(3) {
                slackSend(channel: "#protocol-design-notify", color: "danger", message: ":red_circle: ${SLACK_MESSAGE}")
            }
        }
    }
}
