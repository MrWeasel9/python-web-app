# DevOps Project: Kubernetes Cluster Deployment of a Python Web Application 
# ☸️🐳🐍🤵🏻

This project involves developing and deploying a scalable Python Flask web application with a PostgreSQL database, utilizing a comprehensive range of DevOps tools and practices. The application will be containerized using Docker and orchestrated using Kubernetes, with infrastructure managed on Google Cloud using kOps. The database is deployed via a Bitnami Helm chart, and the Flask application communicates with it through an API. 
The deployment pipeline is automated using Jenkins for CI/CD, ensuring continuous integration and delivery. Additionally, the application is monitored using Prometheus and Grafana, providing insights into performance and system metrics. 
This project showcases a complete DevOps workflow, integrating Kubernetes for orchestration, Google Cloud for infrastructure, and Jenkins for seamless deployments.

Key features include:
- Kubernetes cluster setup with **kOps** (Google Cloud).
- **Helm** for managing application deployment.
- A containerised **Python Flask** app using Docker featuring a chatbot as the frontend.
- **Bitnami PostgreSQL** deployed as a StatefulSet for database management.
- API communication between Flask and PostgreSQL.
- **Prometheus** and **Grafana** for monitoring
- Jenkins CI/CD pipeline for automatic deployment

## Prerequisites

- Google Cloud SDK installed and configured.
- Terraform installed (if using for GCP cluster setup).
- kOps installed
- docker installed for building the image
- Kubernetes CLI (`kubectl`) and Helm installed locally.
- Access to Google Cloud with appropriate permissions for provisioning resources.
- A jenkins server configured with the proper credentials for GCP and dockerhub

## Setup
### 0. Clone the repository
```bash
git clone https://github.com/MrWeasel9/python-web-app
cd python-web-app
```
### 1. Building and pushing the docker image

1. **Download and install `docker` and `kubectl`**:
  ```bash
  curl -fsSL https://get.docker.com/ | sh
  sudo usermod -aG docker <your_username>
  
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  ```
2. Build and push the docker image:
  ```bash
  docker login
  docker build -t <your-repository>/<app-name>:<tag> .
  docker push <your-repository>/<app-name>:<tag>
  docker rmi <your-repository>/<app-name>:<tag>
  ```

### 2. Deploying the Kubernetes Cluster

1. **Download and install the `gcloud` SDK**:
   ```bash
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   ```
2. Set up `gcloud`:
    ```bash
    gcloud init
    gcloud auth login
    gcloud auth application-default login
    gcloud config set project <YOUR_PROJECT_ID>
    ```
3. Installing kOps:
    ```bash
    curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
    chmod +x kops
    sudo mv kops /usr/local/bin/kops
    ```
4. Set up the kOps environment:
    Create a Google Cloud Storage bucket for kOps state:
    ```bash
    gsutil mb gs://<your-kops-state-store>
    ```
    Export the state store environment variable:
    ```bash
    export KOPS_STATE_STORE=gs://your-kops-state-store
    ```
5. Create a Kubernetes cluster configuration:
    ```bash
    kops create cluster --name=your.cluster.name --zones=us-central1-a --state=$KOPS_STATE_STORE
    ```
6. Deploy the cluster:
    ```bash
    kops update cluster your.cluster.name --yes
    ```
7. Export the kubeconfig:
    ```bash
    kops export kubeconfig --admin
    ```

### 3. Deploying the Flask Application, PostgreSQL, Prometheus and Grafana:
1. **Install Helm**:
   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```
2. **Deploy PostgreSQL**:
    ```bash
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm install my-postgresql bitnami/postgresql -f ./helm/custom-postgres-values.yaml
    ```

3. **Deploy Flask Application**:
    ```bash
    helm install my-flask-app ./helm/flask-app-chart
    ```
4. **Deploy Prometheus and Grafana**:
    ```bash
    helm install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace -f ./helm/custom-prometheus-values.yaml
    helm install grafana grafana/grafana --namespace monitoring -f ./helm/custom-grafana-values.yaml
    ```

### 4. Accessing the Application
Once the application is deployed, you can access it via the Kubernetes service. If using an external load balancer, retrieve the external IP:

  ```bash
  kubectl get svc
  kubectl get svc --namespace monitoring
  kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode   ; echo            
  ```
Then, on any web browser just use http://your-ip-address:4000/

### 5. Deploying on CI/CD Jenkins
  - Set up a Jenkins server, update the default plugins, add the google cloud and docker hub credentials.
  - Create a new Pipeline with your desired name
  - Link it to this project and check the GitHub hook trigger for GITScm polling
  - In the pipeline definition choose Pipeline Script from SCM
  - Choose Git and set the Script path to "Jenkinsfile"
☸️
