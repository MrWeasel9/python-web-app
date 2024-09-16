pipeline {
    agent any
    stages {
        stage('Clone Repository') {
            steps {
                git url: 'https://github.com/MrWeasel9/python-web-app.git', branch: 'development'
            }
        }
        stage('Setup GCloud SDK') {
            steps {
                withCredentials([file(credentialsId: 'c7f34f26-88e1-4487-af16-b47e1dc0b47a', variable: 'GCLOUD_KEY')]) {
                    sh '''
                    # Activate service account using the key file
                    gcloud auth activate-service-account --key-file=$GCLOUD_KEY
                    
                    # Set the project (optional if already set in key)
                    gcloud config set project internship-project-435019
                    
                    '''
                }
            }
        }
        stage('Deploy Kubernetes cluster with kOps') {
            steps {
                withCredentials([file(credentialsId: 'c7f34f26-88e1-4487-af16-b47e1dc0b47a', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                    export KOPS_STATE_STORE=gs://radu-kubernetes-clusters/
                    export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS
                    
                    # Check if the cluster exists
                    if kops get cluster --name=simple.k8s.local --state=$KOPS_STATE_STORE; then
                        echo "Cluster already exists. Destroying the existing cluster..."
                        kops delete cluster --name=simple.k8s.local --state=$KOPS_STATE_STORE --yes
                    else
                        echo "No existing cluster found. Proceeding with cluster creation."
                    fi
                    
                    # Create the new cluster
                    kops create cluster --name=simple.k8s.local --zones=us-central1-a --state=$KOPS_STATE_STORE
                    kops update cluster --name=simple.k8s.local --yes
                    kops export kubeconfig --admin
                    echo "Waiting for 4 minutes before proceeding..."
                    sleep 240
                    
                    '''
                }
            }
        }
        stage('Helm application deployment') {
            steps {
                withCredentials([file(credentialsId: 'c7f34f26-88e1-4487-af16-b47e1dc0b47a', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                    export KOPS_STATE_STORE=gs://radu-kubernetes-clusters/
                    export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS
                    helm repo add bitnami https://charts.bitnami.com/bitnami
                    helm install my-postgresql bitnami/postgresql -f custom-postgres-values.yaml
                    helm install my-flask-app ./flask-app-chart
                    sleep 300
                    kubectl get svc
                    kubectl get pods
                    '''
                }
            }
        }
    }
    post {
        success {
            echo "Waiting for 1 hour before cluster destruction"
            sleep(time: 1, unit: "HOURS")
            echo "Destroying the cluster"
            sh "kops delete cluster --name=simple.k8s.local --yes"
        }
    }
}
