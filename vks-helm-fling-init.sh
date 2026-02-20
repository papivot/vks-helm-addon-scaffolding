#!/bin/bash

# This script is used to scaffold a new VKS Package leveraging Helm and Carvel.
# It creates the top level folders and files for a new VKS Package.
# It also creates the sample files for the VKS Package.
# It also checks if the required Carvel binaries are present.
# It also provides the sample commands for reference.

set -o pipefail

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "CRITICAL :: $1 could not be found in the PATH. Download and install the latest binary before proceeding." >&2
        exit 1
    fi
}

display_usage() { 
	echo "This script must be run with three arguments." 
	echo -e "\nUsage: $0 name-of-package version-details[x.y.z] registry-info" 
  echo -e "\nExample: $0 headlamp 0.39.0 us-central1-docker.pkg.dev/navneet-410819/whoami6443-public/ \n"
} 

# if less than three arguments supplied, display usage 
	if [  $# -le 2 ] 
	then 
		display_usage
		exit 1
	fi

# Capture arguments
PACKAGE_NAME=$1
PACKAGE_VERSION=$2
REGISTRY=$3

# Validate registry parameter is not empty
if [ -z "$REGISTRY" ]
then
	echo "ERROR: Registry information must be provided."
	display_usage
	exit 1
fi 
 
# check whether user had supplied -h or --help . If yes display usage 
	if [[ ( $@ == "--help") ||  $@ == "-h" ]] 
	then 
		display_usage
		exit 0
	fi 

##################################################
### Check if Carvel binaries are present
##################################################
check_command kctrl
check_command yq
check_command imgpkg
check_command kbld
check_command kapp

##################################################
#### Create the top level folders
##################################################
mkdir -p "$PACKAGE_NAME"
cd "$PACKAGE_NAME" || exit 1

##################################################
##### Create sample files
##################################################

##### Create config/config.yaml file #####
cat > package-build.yml << EOF
apiVersion: kctrl.carvel.dev/v1alpha1
kind: PackageBuild
metadata:
  creationTimestamp: null
  name: ${PACKAGE_NAME}.vsphere.fling.vmware.com
spec:
  release:
  - resource: {}
  template:
    spec:
      app:
        spec:
          deploy:
          - kapp: {}
          template:
          - helmTemplate:
              path: upstream
          - ytt:
              paths:
              - '-'
          - kbld: {}
      export:
      - imgpkgBundle:
          image: ${REGISTRY}${PACKAGE_NAME}
          useKbldImagesLock: true
        includePaths:
        - upstream
EOF

#### Create top level package-resources.yaml sample file #####
cat > package-resources.yml << EOF
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  creationTimestamp: null
  name: $PACKAGE_NAME.vsphere.fling.vmware.com.$PACKAGE_VERSION
spec:
  refName: $PACKAGE_NAME.vsphere.fling.vmware.com
  releasedAt: null
  template:
    spec:
      deploy:
      - kapp: {}
      fetch:
      - git: {}
      template:
      - helmTemplate:
          path: upstream
      - ytt:
          paths:
          - '-'
      - kbld: {}
  valuesSchema:
    openAPIv3: null
  version: $PACKAGE_VERSION
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  name: $PACKAGE_NAME.vsphere.fling.vmware.com
spec:
  categories:
  - K8s addon
  - VKS Package
  displayName: $PACKAGE_NAME
  iconSVGBase64: none
  longDescription: $PACKAGE_NAME is used to deploy instance of .....
  shortDescription: $PACKAGE_NAME.vsphere.fling.vmware.com
  maintainers:
  - name: supervisor-services-labs.pdl@broadcom.com 
  providerName: VMware
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  annotations:
    kctrl.carvel.dev/local-fetch-0: .
    creationTimestamp: null
  name: $PACKAGE_NAME
spec:
  packageRef:
    refName: $PACKAGE_NAME.vsphere.fling.vmware.com
    versionSelection:
      constraints: $PACKAGE_VERSION
  serviceAccountName: $PACKAGE_NAME-sa
EOF

cat > AddonConfigDefinition-template.yml << EOF
apiVersion: addons.kubernetes.vmware.com/v1alpha1
kind: AddonConfigDefinition
metadata:
  name: $PACKAGE_NAME.vsphere.fling.vmware.com.$PACKAGE_VERSION
  namespace: vmware-system-vks-public
spec:
  templateOutputResources:
    - targetClusterOutput:
        apiVersion: v1
        kind: Secret
        name: '{{.Cluster.name}}-$PACKAGE_NAME-values'
        namespace: vmware-system-tkg
        referenceType: ValuesRef
      template: |-
        stringData:
          values.yaml: |
        {{ toYaml .Values | indent 4}}
  schema:
    openAPIV3Schema:
      type: object
      properties:
EOF

echo 
echo
echo "1. Execute helm search repo <repo_name>/<chart_name> --versions to identify the chart versions supported."
echo
echo "2. Execure kctrl package init to initialize the package."
echo
echo "3. Remove references to docker.io from the helm cart that has been downlaaded in $PACKAGE_NAME/upstream"
echo
echo "4. Execute kctrl package release --openapi-schema --version $PACKAGE_VERSION --repo-output ../repo "
echo "---"
