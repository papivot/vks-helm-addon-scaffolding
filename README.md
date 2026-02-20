# VKS Addon Management Repository

This repository is used to build a VKS Addon Management Repository with individual Helm charts converted into Carvel packages. These packages can then be consumed by the VKS Addon Management Framework.

## Prerequisites

Before you begin, ensure you have the following tools installed:

*   **Helm**: [Install Helm](https://helm.sh/docs/intro/install/)
*   **Carvel Suite**:
    *   `kctrl`: [Install kctrl](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kctrl-cli)
    *   `ytt`: [Install ytt](https://carvel.dev/ytt/docs/latest/install/)
    *   `imgpkg`: [Install imgpkg](https://carvel.dev/imgpkg/docs/latest/install/)
    *   `kbld`: [Install kbld](https://carvel.dev/kbld/docs/latest/install/)
    *   `kapp`: [Install kapp](https://carvel.dev/kapp/docs/latest/install/)
*   **yq** (v4+): [Install yq](https://github.com/mikefarah/yq#install)
*   **kubectl**: [Install kubectl](https://kubernetes.io/docs/tasks/tools/)

## Repository Structure

*   `repo/`: Contains the Carvel package repository configuration and generated package YAMLs.
*   `vks-helm-fling-init.sh`: Scaffolds a new package directory.
*   `vks-helm-fling-step1.sh`: Processes a released package for VKS usage and generates addon templates.

## Workflow

### 1. Setup Helm Repositories

Add the necessary Helm repositories and update them.

```bash
helm repo add <repo-name> <repo-url>
helm repo update
```

Find the chart version you want to package:

```bash
# Grab the repo URL 
helm repo list
# Get the latest version
helm search repo <chart-name> --versions
helm search repo [reponame]
# e.g.
#         --- chart name                  --- chart version
#         (without kedacore)  
#kedacore/keda                           	2.19.0       	2.19.0     	Event-based autoscaler for workloads on Kubernetes
#kedacore/keda-add-ons-http              	0.12.1       	0.12.1     	Event-based autoscaler for HTTP workloads on Ku...
#kedacore/external-scaler-azure-cosmos-db	0.1.0        	0.1.0      	Event-based autoscaler for Azure Cosmos DB chan...

```
Optional: Login to the Registry before proceeding -

```bash
docker login registry.domainname.com -u username
Password: 
Login Succeeded
```

### 2. Initialize Package Scaffolding

Run `vks-helm-fling-init.sh` to create the initial directory structure and configuration files.

```bash
./vks-helm-fling-init.sh <package-name> <package-version> <registry-url>
```

*   `package-name`: Name of the package (e.g., `headlamp`).
*   `package-version`: Version of the package (e.g., `0.39.0`).
*   `registry-url`: OCI registry URL where the package bundle will be stored (e.g., `registry.domainname.com/vks-helm/`).

### 3. Initialize Carvel Package

Navigate to the package directory and initialize the package using `kctrl`.

```bash
cd <package-name>
kctrl package init

### Sample output
Welcome! Before we start, do install the latest Carvel suite of tools, specifically ytt, imgpkg, vendir and kbld.

Basic Information
A package reference name must be at least three '.' separated segments,e.g.
samplepackage.corp.com
> Enter the package reference name (falco.vsphere.fling.vmware.com):

Content
Please provide the location from where your Kubernetes manifests or Helm chart can be fetched. This will be bundled as a part of the package.
1: Local Directory
2: Github Release
3: Helm Chart from Helm Repository
4: Git Repository
5: Helm Chart from Git Repository
> Enter source (3):

> Enter helm chart repository URL (https://falcosecurity.github.io/charts):
> Enter helm chart name (falco):
> Enter helm chart version (8.0.0):
```

Follow the prompts:
*   Select **Helm Chart from Helm Repository** (usually option 3).
*   Enter the Helm repository URL, chart name, and version. (see example above)

### 4. Customize Upstream (Important)

Navigate to the `upstream` directory and modify any files if necessary. A common task is to replace Docker Hub image references with a mirror or private registry if required.

```bash
# Example: Replace docker.io references
# find upstream -type f -exec sed -i '' 's|docker.io|mirror.gcr.io|g' {} \;
```

### 5. Release Package

Build and release the package. This pushes the image bundle to the registry and generates the package lock file.

```bash
kctrl package release --openapi-schema --version <package-version> --repo-output ../repo

### Sample output
Prerequisites
1. Host is authorized to push images to a registry (can be set up by running
`docker login`)
2. `package init` ran successfully.

The bundle created needs to be pushed to an OCI registry. (format:
<REGISTRY_URL/REPOSITORY_NAME>) e.g. index.docker.io/k8slt/sample-bundle
> Enter the registry URL (registry.domainname.com/vks-helm-labs/falco):

```

### 6. Process for VKS

Run `vks-helm-fling-step1.sh` to generate the VKS Addon definition and install templates.

```bash
# Ensure you are in the root of the repository (parent of package directory)
./vks-helm-fling-step1.sh <package-name> <package-version> <registry-url>
```

This script will:
*   Generate `AddonConfigDefinition`.
*   Generate `AddonInstall-template.yml` and `AddonConfig-template.yml`.
*   Update the package YAML in `repo/packages` with the VKS addon definition.

### 7. Release Repository

Finally, update and release the package repository.

```bash
cd repo
kctrl package repository release --version <repo-version>
```

Update `repo/addon-repository.yml` with the new repository image bundle URL if necessary.

## Consuming Addons

Once the repository is deployed to your cluster, you can consume the addons using the generated templates. See [CONSUMING_ADDONS.md](CONSUMING_ADDONS.md) for detailed instructions.
