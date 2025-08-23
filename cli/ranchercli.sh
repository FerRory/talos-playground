#
# Rancher
#
# https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster

helm repo add rancher-latest https://releases.rancher.com/server-charts/latest




kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.0/cert-manager.crds.yaml


helm repo add jetstack https://charts.jetstack.io

helm repo update


helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=false


  helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.brightcubes.nl \
  --set bootstrapPassword=admin

# Change service rancher from ClusterIP to NodePort.
kubectl edit service rancher -n cattle-system


# Open service rancher https port in firewall
az network nsg rule create \
  -g $GROUP \
  --nsg-name talos-sg \
  -n rancher \
  --priority 1005 \
  --destination-port-ranges 31964 \
  --direction inbound


https://20.61.63.134:31964



helm repo add longhorn https://charts.longhorn.io

helm repo update

kubectl apply -f 	longhorn-namespace.yaml	
  helm install longhorn longhorn/longhorn --namespace longhorn-system

kubectl apply -f longhorn-backup-target.yml
