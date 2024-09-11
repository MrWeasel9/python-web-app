# DevOps Project: Kubernetes Cluster Deployment with Flask and PostgreSQL

This project demonstrates the deployment of a Kubernetes cluster on Google Cloud using kOps, with a Python Flask application interacting with a PostgreSQL database. The database is deployed using a Bitnami Helm chart and the application communicates with it via an API.

## Table of Contents
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
  - [1. Deploying the Kubernetes Cluster](#1-deploying-the-kubernetes-cluster)
  - [2. Deploying the Flask Application and PostgreSQL](#2-deploying-the-flask-application-and-postgresql)
- [Accessing the Application](#accessing-the-application)
- [Configuration](#configuration)
- [Contributing](#contributing)

## Project Overview
This project aims to showcase a complete DevOps workflow, from infrastructure provisioning to application deployment. It uses a combination of Kubernetes, Helm, Ansible, and Terraform to automate cluster setup, deploy a Python Flask web application, and manage a PostgreSQL database.

Key features include:
- Kubernetes cluster setup with **kOps** (Google Cloud).
- **Helm** for managing application deployment.
- A **Python Flask** app as the frontend.
- **Bitnami PostgreSQL** deployed as a StatefulSet for database management.
- API communication between Flask and PostgreSQL.

## Architecture

1. **Kubernetes Cluster**: Provisioned using kOps (on Google Cloud).
2. **PostgreSQL Database**: Deployed as a StatefulSet using the Bitnami Helm chart.
3. **Flask Application**: A Python Flask application communicating with the database via an API endpoint.
4. **Helm**: Used for deploying both the Flask app and PostgreSQL.

## Prerequisites

- Google Cloud SDK or Azure CLI installed and configured.
- Terraform installed (if using for GCP cluster setup).
- Kubernetes CLI (`kubectl`) and Helm installed locally.
- Access to Google Cloud with appropriate permissions for provisioning resources.

## Setup

### 1. Deploying the Kubernetes Cluster

#### On Google Cloud (kOps)
1. **Download and install the `gcloud` SDK**:
   ```bash
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   ```
2. Set up `gcloud`:
    ```bash
    gcloud init
    gcloud auth login
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
    kops create cluster --name=your-cluster-name --zones=us-central1-a --state=$KOPS_STATE_STORE
    ```
6. Deploy the cluster:
    ```bash
    kops update cluster your-cluster-name --yes
    kops validate cluster
    ```

### 2. Deploying the Flask Application and PostgreSQL

1. **Deploy PostgreSQL using Helm**:
    ```bash
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm install my-postgresql bitnami/postgresql -f custom-postgres-values.yaml
    ```

2. **Deploy Flask Application**:
    - Package the Flask application into a Docker image.
    - Push the image to a container registry (e.g., Docker Hub or Google Container Registry).
    - Deploy the Flask app using Helm:
    ```bash
    helm install my-flask-app ./flask-chart
    ```

### Accessing the Application
Once the application is deployed, you can access it via the Kubernetes service. If using an external load balancer, retrieve the external IP:

```bash
kubectl get svc my-flask-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
```
Then, on any web browser just use http://your-ip-address:4000/
