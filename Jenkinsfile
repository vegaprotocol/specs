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
                        sh 'godog --format=junit:qa-scenarios-report.xml ../../specs-internal/qa-scenarios/'
                        junit 'qa-scenarios-report.xml'
                    }
                }
            }
        }
    }
}
