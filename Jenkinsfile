pipeline {
    agent { label 'general' }
    options {
        skipDefaultCheckout true
    }
    environment {
        GO111MODULE = 'on'
    }

    stages {
        stage('Git clone') {
            parallel {
                stage('specs-internal') {
                    steps {
                        retry(3) {
                            dir('specs-internal') {
                                checkout scm
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

        stage('Run qa-scenarios') {
            steps {
                retry(3) {
                    dir('vega/integration') {
                        sh 'godog -format=junit ../../specs-internal/qa-scenarios/ | grep -v "^202" | grep -v "^\\s*$" > qa-scenarios-report.xml'
                        junit skipPublishingChecks: true, testResults: 'qa-scenarios-report.xml'
                        sh 'godog ../../specs-internal/qa-scenarios/'
                    }
                }
            }
        }
    }
}
