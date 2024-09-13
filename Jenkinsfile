pipeline {
    agent any

    environment {
        // Define environment variables for your project
        KOPS_STATE_STORE = 'gs://radu-kubernetes-clusters/'
        CLUSTER_NAME = 'simple.k8s.local'
        DOCKER_REGISTRY = 'mrweasel99'
        FLASK_IMAGE = "${DOCKER_REGISTRY}/flask-app:latest"
        HELM_CHART_DIR = './flask-chart'
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcloud-service-account') // Use the credentials ID here
        CLOUD_SDK_DIR = '/var/lib/jenkins/google-cloud-sdk'
    }

    stages {
        stage('Checkout') {
            steps {
                // Check out the source code from the Git repository
                git branch: 'development', url: 'https://github.com/MrWeasel9/python-web-app.git'
            }
        }

        stage('Install/Update gcloud SDK') {
            steps {
                script {
                    // Check if Google Cloud SDK is installed
                    def isInstalled = sh(script: "test -d ${CLOUD_SDK_DIR}", returnStatus: true) == 0
                    if (isInstalled) {
                        // Update existing SDK
                        sh '''
                        source ${CLOUD_SDK_DIR}/google-cloud-sdk/path.bash.inc
                        gcloud components update --quiet
                        '''
                    } else {
                        // Install Google Cloud SDK
                        sh '''
                        curl https://sdk.cloud.google.com | bash
                        mkdir -p ${CLOUD_SDK_DIR}
                        curl -o google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.tar.gz
                        tar -C ${CLOUD_SDK_DIR} -xzf google-cloud-sdk.tar.gz
                        source ${CLOUD_SDK_DIR}/google-cloud-sdk/path.bash.inc
                        gcloud --version
                        '''
                    }
                }
            }
        }

        stage('Authenticate gcloud') {
            steps {
                script {
                    // Authenticate with Google Cloud using the service account
                    sh '''
                    echo "$GOOGLE_APPLICATION_CREDENTIALS" > /tmp/account.json
                    gcloud auth activate-service-account --key-file=/tmp/account.json
                    gcloud config set project internship-project-435019
                    '''
                }
            }
        }

        stage('Install kOps') {
            steps {
                // Install kOps
                sh '''
                curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
                chmod +x kops
                sudo mv kops /usr/local/bin/kops
                '''
            }
        }

        stage('Create Kubernetes Cluster') {
            steps {
                script {
                    // Create Kubernetes cluster with kOps
                    sh '''
                    kops create cluster --name=${CLUSTER_NAME} --zones=us-central1-a --state=${KOPS_STATE_STORE}
                    kops update cluster ${CLUSTER_NAME} --yes
                    kops validate cluster --wait 4m
                    kops export kubeconfig --admin
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image for Flask app
                    dockerImage = docker.build("${FLASK_IMAGE}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Push Docker image to Docker registry
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                        dockerImage.push()
                    }
                }
            }
        }

        stage('Deploy PostgreSQL') {
            steps {
                script {
                    // Deploy PostgreSQL using Helm
                    sh '''
                    helm repo add bitnami https://charts.bitnami.com/bitnami
                    helm install my-postgresql bitnami/postgresql -f custom-postgres-values.yaml
                    '''
                }
            }
        }

        stage('Deploy Flask Application') {
            steps {
                script {
                    // Deploy Flask app using Helm
                    sh 'helm install my-flask-app ${HELM_CHART_DIR}'
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    // Verify the deployment status
                    sh 'kubectl get pods'
                    sh 'kubectl get services'
                }
            }
        }

        stage('Retrieve External IP') {
            steps {
                script {
                    // Retrieve external IP of Flask app
                    sh 'kubectl get svc my-flask-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}"'
                }
            }
        }
    }

    post {
        always {
            // Clean workspace after build
            cleanWs()
        }
    }
}
