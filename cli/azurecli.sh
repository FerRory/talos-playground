#!/bin/bash
# Storage account to use
export STORAGE_ACCOUNT="talos-storage"

# Storage container to upload to
export STORAGE_CONTAINER="talos-container"

# Resource group name
export GROUP="talos"

# Location
export LOCATION="westeurope"

# Get storage account connection string based on info above
export CONNECTION=$(az storage account show-connection-string \
                    -n $STORAGE_ACCOUNT \
                    -g $GROUP \
                    -o tsv)





az storage account create --name $STORAGE_ACCOUNT \
                          --resource-group $GROUP \
                          --access-tier Hot \
                          --location $LOCATION


# Get storage account connection string based on info above
export CONNECTION=$(az storage account show-connection-string \
                    -n $STORAGE_ACCOUNT \
                    -g $GROUP \
                    -o tsv)

 az storage blob upload \
  --connection-string $CONNECTION \
  --container-name $STORAGE_CONTAINER \
  -f ./azure-amd64.vhd \
  --overwrite \
  -n talos-azure.vhd     



 az image create \
  --name talos \
  --source https://$STORAGE_ACCOUNT.blob.core.windows.net/$STORAGE_CONTAINER/talos-azure.vhd \
  --os-type linux \
  -g $GROUP 

az image delete -n talos -g talos
# Create vnet
az network vnet create \
  --resource-group $GROUP \
  --location $LOCATION \
  --name talos-vnet \
  --subnet-name talos-subnet

# Create network security group
az network nsg create -g $GROUP -n talos-sg

# Client -> apid
az network nsg rule create \
  -g $GROUP \
  --nsg-name talos-sg \
  -n apid \
  --priority 1001 \
  --destination-port-ranges 50000 \
  --direction inbound

# Trustd
az network nsg rule create \
  -g $GROUP \
  --nsg-name talos-sg \
  -n trustd \
  --priority 1002 \
  --destination-port-ranges 50001 \
  --direction inbound

# etcd
az network nsg rule create \
  -g $GROUP \
  --nsg-name talos-sg \
  -n etcd \
  --priority 1003 \
  --destination-port-ranges 2379-2380 \
  --direction inbound

# Kubernetes API Server
az network nsg rule create \
  -g $GROUP \
  --nsg-name talos-sg \
  -n kube \
  --priority 1004 \
  --destination-port-ranges 6443 \
  --direction inbound


# Create public ip
az network public-ip create \
  --resource-group $GROUP \
  --name talos-public-ip \
  --allocation-method static

# Create lb
az network lb create \
  --resource-group $GROUP \
  --name talos-lb \
  --public-ip-address talos-public-ip \
  --frontend-ip-name talos-fe \
  --backend-pool-name talos-be-pool

# Create health check
az network lb probe create \
  --resource-group $GROUP \
  --lb-name talos-lb \
  --name talos-lb-health \
  --protocol tcp \
  --port 6443

# Create lb rule for 6443
az network lb rule create \
  --resource-group $GROUP \
  --lb-name talos-lb \
  --name talos-6443 \
  --protocol tcp \
  --frontend-ip-name talos-fe \
  --frontend-port 6443 \
  --backend-pool-name talos-be-pool \
  --backend-port 6443 \
  --probe-name talos-lb-health

for i in $( seq 0 1 2 ); do
  # Create public IP for each nic
  az network public-ip create \
    --resource-group $GROUP \
    --name talos-controlplane-public-ip-$i \
    --allocation-method static


  # Create nic
  az network nic create \
    --resource-group $GROUP \
    --name talos-controlplane-nic-$i \
    --vnet-name talos-vnet \
    --subnet talos-subnet \
    --network-security-group talos-sg \
    --public-ip-address talos-controlplane-public-ip-$i\
    --lb-name talos-lb \
    --lb-address-pools talos-be-pool
done

LB_PUBLIC_IP=$(az network public-ip show \
              --resource-group $GROUP \
              --name talos-public-ip \
              --query "ipAddress" \
              --output tsv)

#talosctl gen config rory-azure-talos https://${LB_PUBLIC_IP}:6443

# Create the control plane nodes
# Create availability set
az vm availability-set create \
  --name talos-controlplane-av-set \
  -g $GROUP

for i in $( seq 0 1 2 ); do
  az vm create \
    --name talos-controlplane-$i \
    --image talos \
    --custom-data ./controlplane.yaml \
    -g $GROUP \
    --admin-username talos \
    --generate-ssh-keys \
    --verbose \
    --boot-diagnostics-storage $STORAGE_ACCOUNT \
    --os-disk-size-gb 20 \
    --nics talos-controlplane-nic-$i \
    --availability-set talos-controlplane-av-set \
    --size Standard_D2s_V5 \
    --no-wait
done

# Create worker node
 az vm create \
    --name talos-worker-0 \
    --image talos \
    --vnet-name talos-vnet \
    --subnet talos-subnet \
    --custom-data ./worker.yaml \
    -g $GROUP \
    --admin-username talos \
    --generate-ssh-keys \
    --verbose \
    --boot-diagnostics-storage $STORAGE_ACCOUNT \
    --nsg talos-sg \
    --os-disk-size-gb 20 \
    --size Standard_D2s_V5 \
    --no-wait



# Get Control plane IP:

CONTROL_PLANE_0_IP=$(az network public-ip show \
                    --resource-group $GROUP \
                    --name talos-controlplane-public-ip-0 \
                    --query "ipAddress" \
                    --output tsv)


# Set endpoints:

talosctl --talosconfig talosconfig config endpoint $CONTROL_PLANE_0_IP
talosctl --talosconfig talosconfig config node $CONTROL_PLANE_0_IP

# Bootstrap etcd
talosctl --talosconfig talosconfig bootstrap

# Retrieve the kubeconfig:
talosctl --talosconfig talosconfig kubeconfig .


# Alias:
alias k="kubectl"

k get nodes



# Create additonal worker node
 az vm create \
    --name talos-worker-1 \
    --image talos \
    --vnet-name talos-vnet \
    --subnet talos-subnet \
    --custom-data ./worker.yaml \
    -g $GROUP \
    --admin-username talos \
    --generate-ssh-keys \
    --verbose \
    --boot-diagnostics-storage $STORAGE_ACCOUNT \
    --nsg talos-sg \
    --os-disk-size-gb 20 \
    --size Standard_D2s_V5 \
    --no-wait




az vm deallocate --ids $(az vm list -g $GROUP --query "[].id" -o tsv)


az vm start --ids $(az vm list -g $GROUP --query "[].id" -o tsv)

 az vm delete --ids $(az vm list -g $GROUP --query "[].id" -o tsv) -y


az network nsg rule create \
  -g $GROUP \
  --nsg-name talos-sg \
  -n rancher \
  --priority 1005 \
  --destination-port-ranges 32452 \
  --direction inbound



 az vm create \
    --name talos-worker-big-0 \
    --image talos \
    --vnet-name talos-vnet \
    --subnet talos-subnet \
    --custom-data ./worker.yaml \
    -g $GROUP \
    --admin-username talos \
    --generate-ssh-keys \
    --verbose \
    --boot-diagnostics-storage $STORAGE_ACCOUNT \
    --nsg talos-sg \
    --os-disk-size-gb 80 \
    --size Standard_D2s_V5 \
    --no-wait

 az vm create \
    --name talos-worker-big-1 \
    --image talos \
    --vnet-name talos-vnet \
    --subnet talos-subnet \
    --custom-data ./worker.yaml \
    -g $GROUP \
    --admin-username talos \
    --generate-ssh-keys \
    --verbose \
    --boot-diagnostics-storage $STORAGE_ACCOUNT \
    --nsg talos-sg \
    --os-disk-size-gb 80 \
    --size Standard_D2s_V5 \
    --no-wait

 az vm create \
    --name talos-worker-big-2 \
    --image talos \
    --vnet-name talos-vnet \
    --subnet talos-subnet \
    --custom-data ./worker.yaml \
    -g $GROUP \
    --admin-username talos \
    --generate-ssh-keys \
    --verbose \
    --boot-diagnostics-storage $STORAGE_ACCOUNT \
    --nsg talos-sg \
    --os-disk-size-gb 80 \
    --size Standard_D2s_V5 \
    --no-wait


customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/iscsi-tools
            - siderolabs/util-linux-tools
