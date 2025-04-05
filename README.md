# GEL UI Kubernetes Issue minimal reproduction

This is an example of what is not working with Gel UI based on [this](https://discord.com/channels/841451783728529451/849377751370432573/1357702438433587344) discord thread.

## Prerequisites

- A Kubernetes environment (e.g., minikube)
- [Helm](https://helm.sh/docs/intro/install/) package manager
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) CLI tool
- Gel CLI
- This repository's files

## Setup Instructions

1. Clone this repository:
   ```bash
   git clone git@github.com:Sampiiiii/gel-ui-k8s-issue-reproduction.git
   cd ui-minimal-reproduction
   ```

2. Make the setup script executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run the setup script:
   ```bash
   ./setup.sh
   ```

The setup script will:
- Add required Helm repositories (CNPG and cert-manager)
- Create necessary namespaces
- Install cert-manager
- Install CloudNative PostgreSQL operator
- Create Gel namespace and resources
- Configure certificates
- Deploy Gel and its database
- Verify all installations

The script is interactive and will ask for confirmation before each major step. You can review the progress and final status of all components at the end of the installation.

## Reproducing the issue

Once the cluster is setup and running you can recreate the UI issue by linking to the instance by running

1. Extract the Cert
```
kubectl get secret gel-ca -n gel -o jsonpath='{.data.tls\.crt}' | base64 -d > gel-ca.crt
```
2. Port forward gel from k8s
```
kubectl port-forward --namespace gel service/gel 5656:5656
```

3. Export DSN
```
export GEL_DSN="gel://edgedb:gel-password@localhost:5656/main"
```
4. Link Instance
```
gel instance link --dsn=$GEL_DSN  --tls-ca-file=./gel-ca.crt
```
5. Run UI
```
gel -I <instance name> ui
```

6. Go to url and login with credentials 
```
username: admin
password: gel-password
```


###
Result it will not load the UI like shown in the discord thread 

Hopefully this reporduction works (tested on M3 Macos with Orbstack K8s)