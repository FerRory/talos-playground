# Talos Playground on Azure

## Talos Image from factory.talos.dev:
URL: https://factory.talos.dev/image/613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245/v1.10.6/azure-amd64.vhd.xz

Extensions:

customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/iscsi-tools
            - siderolabs/util-linux-tools


## Terraform

Terraform is working, only fails at image creation, after a retry it works. 
