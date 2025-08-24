

resource "null_resource" "talos_config" {
  provisioner "local-exec" {
    command = "cd ../secrets/; talosctl gen config rory-azure-talos https://${azurerm_public_ip.talos_lb.ip_address}:6443 --force"
  }

  depends_on  = [azurerm_public_ip.talos_lb]
  
}

output "lb_public_ip" {
  value = azurerm_public_ip.talos_lb.ip_address
}

# Setting Talos config with talosctl
resource "null_resource" "talos_setting_config" {
  provisioner "local-exec" {
    command = <<EOT
      set -e
      cd ../secrets/
      CONTROL_PLANE_0_IP=${azurerm_public_ip.controlplane[0].ip_address}

      echo "Setting Talos endpoint and node to $CONTROL_PLANE_0_IP"
      talosctl --talosconfig talosconfig config endpoint $CONTROL_PLANE_0_IP
      talosctl --talosconfig talosconfig config node $CONTROL_PLANE_0_IP

    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on  = [azurerm_public_ip.controlplane[0], null_resource.talos_config]
  
}


# Bootstrap Talos cluster with talosctl
resource "null_resource" "talos_bootstrap" {
  provisioner "local-exec" {
    command = <<EOT
      set -e
      cd ../secrets/
      echo "Bootstrapping Talos..."
      talosctl --talosconfig talosconfig bootstrap

      echo "Retrieving kubeconfig..."
      talosctl --talosconfig talosconfig kubeconfig .
      cp kubeconfig ~/.kube/config
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [azurerm_linux_virtual_machine.controlplane[2]]
  
}


output "controlplane_0_ip" {
  value = azurerm_public_ip.controlplane[0].ip_address
}