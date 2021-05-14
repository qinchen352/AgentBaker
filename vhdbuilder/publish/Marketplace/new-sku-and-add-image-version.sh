#!/bin/bash -xeu

required_env_vars=(
    "SKU_PREFIX"
    "SKU_TEMPLATE_FILE"
    "AZURE_TENANT_ID"
    "AZURE_CLIENT_ID"
    "AZURE_CLIENT_SECRET"
    "PUBLISHER"
    "OFFER"
    "CONTAINER_RUNTIME"
)

for v in "${required_env_vars[@]}"
do
    if [ -z "${!v}" ]; then
        echo "$v was not set!"
        exit 1
    fi
done

if [ ! -f "$SKU_TEMPLATE_FILE" ]; then
    echo "Could not find sku template file: ${SKU_TEMPLATE_FILE}!"
    exit 1
fi

echo "Get token"
az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
token=$(az account get-access-token --resource https://cloudpartner.azure.com --query "accessToken" -o tsv)
export AZURE_TOKEN=$token

ls -lhR artifacts
vhd_artifacts_path="publishing-info-2019"
if [[ ${CONTAINER_RUNTIME} = "containerd" ]]; then
    vhd_artifacts_path="publishing-info-2019-containerd"
fi
VHD_INFO="artifacts/vhd/${vhd_artifacts_path}/vhd-publishing-info.json"
if [ ! -f "$VHD_INFO" ]; then
    echo "Could not find VHD info file: ${VHD_INFO}!"
    exit 1
fi

short_date=$(date +"%y%m")
pretty_date=$(date +"%b %Y")
sku_id="${SKU_PREFIX}-${short_date}"
echo "Checking if offer contains SKU: $sku_id"
# Check if SKU already exists in offer
hack/tools/bin/pub skus list -p $PUBLISHER -o $OFFER