#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Confirmation function
confirm() {
  read -r -p "${1} [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY]) 
      true
      ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
}

# Function to add Helm repositories
add_helm_repos() {
  echo "This step will add the required Helm repositories for CNPG and cert-manager."
  confirm "Do you want to continue?"
  
  echo "Adding Helm repositories..."
  helm repo add cnpg https://cloudnative-pg.github.io/charts
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
}

# Function to create namespaces
create_namespaces() {
  echo "This step will create the required namespaces (cnpg-system and cert-manager)."
  confirm "Do you want to continue?"
  
  echo "Creating namespaces..."
  # Create CloudNative PG namespace
  kubectl create namespace cnpg-system --dry-run=client -o yaml | kubectl apply -f -
  # Create cert-manager namespace
  kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
}

# Function to install CloudNative PostgreSQL operator
install_cnpg() {
  echo "This step will install the CloudNative PostgreSQL operator."
  confirm "Do you want to continue?"
  
  echo "Installing CloudNative PostgreSQL operator..."
  helm upgrade --install cnpg --namespace cnpg-system cnpg/cloudnative-pg
  
  # Wait for CNPG operator to be ready
  echo "Waiting for CNPG operator to be ready..."
  kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cloudnative-pg -n cnpg-system --timeout=120s
}

# Function to install cert-manager
install_cert_manager() {
  echo "This step will install cert-manager v1.13.3."
  confirm "Do you want to continue?"
  
  echo "Installing cert-manager..."
  helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.13.3 \
    --set installCRDs=true \
    --wait

  # Wait for cert-manager webhook to be ready
  echo "Waiting for cert-manager webhook to be ready..."
  kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=webhook -n cert-manager --timeout=120s
}

# Function to create gel namespace and initial resources
create_gel_namespace() {
  echo "This step will create the Gel namespace and initial resources."
  confirm "Do you want to continue?"
  
  echo "Creating Gel namespace and resources..."
  kubectl apply -f k8s/namespace.yaml
  kubectl apply -f k8s/secrets.yaml
}

# Function to apply certificates
apply_certificates() {
  echo "This step will apply the certificate configuration for Gel."
  confirm "Do you want to continue?"
  
  echo "Applying certificate configuration..."
  kubectl apply -f k8s/certificate.yaml
  
  # Wait for the CA certificate to be ready
  echo "Waiting for CA certificate to be ready..."
  kubectl wait --for=condition=ready certificate -n gel gel-ca --timeout=60s
  
  # Wait for the server certificate to be ready
  echo "Waiting for server certificate to be ready..."
  kubectl wait --for=condition=ready certificate -n gel gel-server-cert --timeout=60s
}

# Function to apply remaining Gel resources using kustomize
apply_gel_resources() {
  echo "This step will apply all remaining Gel resources (deployment, service, PVC, cluster) using kustomize."
  confirm "Do you want to continue?"
  
  echo "Applying Gel resources using kustomize..."
  kubectl apply -k k8s/
  
  # Wait for PostgreSQL cluster to be ready
  echo "Waiting for PostgreSQL cluster to be ready..."
  kubectl wait --for=condition=ready pod -l app=gel-postgres -n gel --timeout=300s
  
  # Wait for Gel deployment to be ready
  echo "Waiting for Gel deployment to be ready..."
  kubectl wait --for=condition=ready pod -l app=gel -n gel --timeout=300s
}

# Function to verify installations
verify_installations() {
  echo "This step will verify the status of all installed components."
  confirm "Do you want to continue?"
  
  echo "Checking CloudNative PostgreSQL operator status..."
  kubectl get pods -n cnpg-system

  echo "Checking cert-manager status..."
  kubectl get pods -n cert-manager
  
  echo "Checking certificates status..."
  kubectl get certificates,certificaterequests,secrets -n gel
  
  echo "Checking Gel and PostgreSQL status..."
  kubectl get pods,svc,pvc -n gel
}

echo "This script will set up a minimal Gel installation with required dependencies."
echo "It will install cert-manager, CloudNative PostgreSQL operator, and deploy Gel with its database."
confirm "Would you like to proceed with the installation?"

# Main installation process
add_helm_repos
create_namespaces
install_cert_manager
install_cnpg
create_gel_namespace
apply_certificates
apply_gel_resources
verify_installations

echo "Installation completed successfully!"
