# BUILDING ADDON PACKAGE REPO FOR HELM CHARTS (for VKS addon Deployment)

0. Setup Helm repos and login to the registry
```bash
helm repo add repo URL1
helm repo add repo URL2
...
helm repo update
```

To get the chart repository URL 
```bash
helm repo list
```

To get latest version - 
```bash
helm search repo [reponame]
# e.g.
#         --- chart name                    --- chart version
#         (without kedacore)  
#kedacore/keda                           	2.19.0       	2.19.0     	Event-based autoscaler for workloads on Kubernetes
#kedacore/keda-add-ons-http              	0.12.1       	0.12.1     	Event-based autoscaler for HTTP workloads on Ku...
#kedacore/external-scaler-azure-cosmos-db	0.1.0        	0.1.0      	Event-based autoscaler for Azure Cosmos DB chan...
```

Login to the Registry before proceeding - 

```bash
docker login registry.domainname.com -u username
Password: 
Login Succeeded
```

1. Run `vks-helm-fling-init.sh` to setup all the dirtory folders structure for a Helm chart

2. To initalize each package - 
```bash
$ kctrl package init

Welcome! Before we start, do install the latest Carvel suite of tools,
specifically ytt, imgpkg, vendir and kbld.

Basic Information
A package reference name must be at least three '.' separated segments,e.g.
samplepackage.corp.com
> Enter the package reference name (falco.vsphere.fling.vmware.com):

Content
Please provide the location from where your Kubernetes manifests or Helm chart
can be fetched. This will be bundled as a part of the package.
1: Local Directory
2: Github Release
3: Helm Chart from Helm Repository
4: Git Repository
5: Helm Chart from Git Repository
> Enter source (3):

> Enter helm chart repository URL (https://falcosecurity.github.io/charts):
> Enter helm chart name (falco):
> Enter helm chart version (8.0.0):
...

```

IMPORTANT STEP
3. Update all files in the upstream folder to remove references to Dockerhub by searching for strings such as `docker`, `image:`, `registry`, `docker.io`

e.g.
```bash
find upstream -type f -exec sed -i '' 's|node:lts-alpine|mirror.gcr.io/library/node:lts-alpine|g' {} \;
```

4. NOTE: Validate/investigate - may need to update `package.spec.template.spec.deploy.kapp.intoNs` to force package install into a specific Namespace within the guest cluster. Some Helm charts to not provide options to force install in a specific NS.

5. Build package 
```bash
$ kctrl package release --openapi-schema --version 8.0.0  --repo-output ../repo

Prerequisites
1. Host is authorized to push images to a registry (can be set up by running
`docker login`)
2. `package init` ran successfully.

The bundle created needs to be pushed to an OCI registry. (format:
<REGISTRY_URL/REPOSITORY_NAME>) e.g. index.docker.io/k8slt/sample-bundle
> Enter the registry URL (vsphere-labs-docker-prod-local.usw5.packages.broadcom.com/vks-helm-labs/falco):
...

```

6. Run `vks-helm-fling-step1.sh` to setup all the directory folders structure for the repo and addon templates.

7. Once all the packages have been built, head over to the repo folder

```bash
kctrl package repository release
```

8. TODO: fix the repo/addon-repository.yaml with the appropriate imageBundle info etc. 