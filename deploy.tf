terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

# There are currently no configuration options for the provider itself.

resource "virtualbox_vm" "node" {
  count  = 2
  name   = format("node-%02d", count.index + 1)
  image  = "https://app.vagrantup.com/ubuntu/boxes/trusty64/versions/20190514.0.0/providers/virtualbox.box"
  cpus   = 2
  memory = "512 mib"
  //user_data = file("${path.module}/user_data")

  network_adapter {
    type           = "hostonly"
    host_interface = "vboxnet1"
  }

  # OPCION 1: EJECUTAR UN COMANDO REMOTO
  # provisioner "remote-exec" {
  #   inline = ["sudo shutdown -h now", ] # Ejecuto un shutdown para comprobar que la conexion ssh se realiza correctamente
  #   connection {
  #     host        = self.network_adapter.0.ipv4_address
  #     type        = "ssh"
  #     user        = "vagrant"
  #     password    = var.password
  #     private_key = file("~/.ssh/id_rsa")
  #   }
  # }

  # OPCION 2: ESTABLECER RELACIÓN DE CONFIANZA ENTRE HOST Y VMs
  provisioner "local-exec" {
    command     = "sshpass -p '${var.password}' ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@${self.network_adapter.0.ipv4_address}"
  }

  provisioner "local-exec" {
    command     = "ansible-playbook -i '${self.network_adapter.0.ipv4_address},' -u vagrant --private-key ~/.ssh/id_rsa.pub setup/install_docker.yml"
    working_dir = path.module
  }
}

output "IPAddr" {
  value = element(virtualbox_vm.node.*.network_adapter.0.ipv4_address, 1)
}

output "IPAddr_2" {
  value = element(virtualbox_vm.node.*.network_adapter.0.ipv4_address, 2)
}
