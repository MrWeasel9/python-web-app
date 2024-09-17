pipeline {
    agent any
    stages {
        stage('Clone Repository') {
            steps {
                git url: 'https://github.com/MrWeasel9/python-web-app.git', branch: 'development'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh '''
                # Build Docker image from the Dockerfile
                docker build -t mrweasel99/python-web-app:latest .
                '''
            }
        }

        stage('Login to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-id', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh '''
                    # Login to Docker Hub using credentials from Jenkins
                    echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                # Push the Docker image to the Docker repository
                docker push mrweasel99/python-web-app:latest
                '''
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                # Remove the image locally after pushing
                docker rmi mrweasel99/python-web-app:latest || true
                '''
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
                sh '''
                helm repo add bitnami https://charts.bitnami.com/bitnami
                helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
                helm repo add grafana https://grafana.github.io/helm-charts
                helm install my-postgresql bitnami/postgresql -f ./helm/custom-postgres-values.yaml
                helm install my-flask-app ./helm/flask-app-chart
                helm install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace -f ./helm/custom-prometheus-values.yaml
                helm install grafana grafana/grafana --namespace monitoring -f ./helm/custom-grafana-values.yaml
                echo "Waiting for 6 minutes before proceeding..."
                sleep 360
                kubectl get svc
                kubectl get pods
                kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
                kubectl get svc --namespace monitoring
                '''
                
            }
        }
        stage('Destroy Kubernetes cluster') {
            steps {
                withCredentials([file(credentialsId: 'c7f34f26-88e1-4487-af16-b47e1dc0b47a', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                    export KOPS_STATE_STORE=gs://radu-kubernetes-clusters/
                    export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS
                    echo "Waiting for 1 hour before cluster destruction"
                    sleep(time: 1, unit: "HOURS")
                    echo "Destroying the cluster"
                    kops delete cluster --name=simple.k8s.local --yes
                    echo "Cluster destroyed"
                    '''
                }
            }
        }
    }
    
}
