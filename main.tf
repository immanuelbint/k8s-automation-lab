# --- Master node resources --- #

data "template_file" "master_user_data" {
    count       = var.master_count
    template    = file("${path.module}/conf/user_data.yaml")
    vars        = {
        hostname = "${var.master_hostname}-${count.index}"
        domain   = var.vm_domain
    }
}

data "template_file" "master_network_config" {
    count       = var.master_count
    template    = file("${path.module}/conf/network_config.yaml")
    vars        = {
    ip_address = var.master_ip_address[count.index]
  }
}

resource "libvirt_volume" "master_instance_vol" {
    count   = var.master_count
    name    = "${var.master_hostname}-${count.index}-vol"
    pool    = var.libvirt_pool_name
    source  = var.base_image_path
    format  = "qcow2"
}

# Master Data Volume
resource "libvirt_volume" "master_data_volume" {
    count   = var.master_count
    name    = "${var.master_hostname}-data-vol-${count.index}"
    pool    = var.master_data_volume[0].pool
    size    = var.master_data_volume[0].size * 1024 * 1024 * 1024
    format  = var.master_data_volume[0].format
}


resource "libvirt_cloudinit_disk" "master_cloudinit" {
    count           = var.master_count
    name            = "${var.master_hostname}-cloudinit.${count.index}.iso"
    user_data       = data.template_file.master_user_data[count.index].rendered
    network_config  = data.template_file.master_network_config[count.index].rendered
    pool            = var.libvirt_pool_name
}

resource "libvirt_domain" "master_node" {
    count       = var.master_count
    name        = "${var.master_hostname}-${count.index}"
    memory      = var.master_memory
    vcpu        = var.master_cpu
    cloudinit   = libvirt_cloudinit_disk.master_cloudinit[count.index].id
    autostart   = true

    depends_on = [
        libvirt_volume.master_instance_vol,
        libvirt_volume.master_data_volume
    ]

    cpu {
        mode = "host-passthrough"
    }

    network_interface {
        bridge          = "virbr0"
        wait_for_lease  = "false"
        hostname        = "${var.master_hostname}-${count.index}"
    }

    console {
        type        = "pty"
        target_port = "0"
        target_type = "serial"
    }

    console {
        type        = "pty"
        target_port = "1"
        target_type = "virtio"
    }

    disk {
        volume_id   = libvirt_volume.master_instance_vol[count.index].id
    }

    disk {
        volume_id   = libvirt_volume.master_data_volume[count.index].id
    }
}

# --- Worker node resources --- #

data "template_file" "worker_user_data" {
    count       = var.worker_count
    template    = file("${path.module}/conf/user_data.yaml")
    vars        = {
        hostname = "${var.worker_hostname}-${count.index}"
        domain   = var.vm_domain
    }
}

data "template_file" "worker_network_config" {
    count       = var.worker_count
    template    = file("${path.module}/conf/network_config.yaml")
    vars        = {
    ip_address = var.worker_ip_address[count.index]
  }
}

# Worker Main Disk
resource "libvirt_volume" "worker_instance_vol" {
    count   = var.worker_count
    name    = "${var.worker_hostname}-vol.${count.index}"
    pool    = var.libvirt_pool_name
    source  = var.base_image_path
    format  = "qcow2"
}

# Worker Data Volume
resource "libvirt_volume" "worker_data_volume" {
    count   = var.worker_count
    name    = "${var.worker_hostname}-data-vol-${count.index}"
    pool    = var.worker_data_volume[0].pool
    size    = var.worker_data_volume[0].size * 1024 * 1024 * 1024
    format  = var.worker_data_volume[0].format
}

resource "libvirt_cloudinit_disk" "worker_cloudinit" {
    count           = var.worker_count
    name            = "${var.worker_hostname}-cloudinit.${count.index}.iso"
    user_data       = data.template_file.worker_user_data[count.index].rendered
    network_config  = data.template_file.worker_network_config[count.index].rendered
    pool            = var.libvirt_pool_name
}

resource "libvirt_domain" "worker_node" {
    count       = var.worker_count
    name        = "${var.worker_hostname}-${count.index}"
    memory      = var.worker_memory
    vcpu        = var.worker_cpu
    cloudinit   = libvirt_cloudinit_disk.worker_cloudinit[count.index].id
    autostart   = true

    depends_on = [
        libvirt_volume.worker_instance_vol,
        libvirt_volume.worker_data_volume
    ]

    cpu {
        mode = "host-passthrough"
    }

    network_interface {
        bridge          = "virbr0"
        wait_for_lease  = "false"
        hostname        = "${var.worker_hostname}-${count.index}"
    }

    console {
        type        = "pty"
        target_port = "0"
        target_type = "serial"
    }

    console {
        type        = "pty"
        target_port = "1"
        target_type = "virtio"
    }

    disk {
        volume_id   = libvirt_volume.worker_instance_vol[count.index].id
    }

    disk {
        volume_id   = libvirt_volume.worker_data_volume[count.index].id
    }
}

resource "null_resource" "run_ansible" {
  depends_on = [
    libvirt_domain.master_node,
    libvirt_domain.worker_node
  ]

  provisioner "local-exec" {
    command = <<EOT
     echo "Waiting for VMs to boot..."
     sleep 300

    echo "[masters]" > ansible/inventory/terraform_inventory.ini
    for ip in ${join(" ", var.master_ip_address)}; do
      echo "$ip" >> ansible/inventory/terraform_inventory.ini

    done
    echo "[workers]" >> ansible/inventory/terraform_inventory.ini
    for ip in ${join(" ", var.worker_ip_address)}; do
      echo "$ip" >> ansible/inventory/terraform_inventory.ini
    done

    echo "[all:vars]" >> ansible/inventory/terraform_inventory.ini
    echo "ansible_ssh_user=${var.ssh_username}" >> ansible/inventory/terraform_inventory.ini
    echo "ansible_ssh_private_key_file=${var.ssh_private_key}" >> ansible/inventory/terraform_inventory.ini
    echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'" >> ansible/inventory/terraform_inventory.ini

    ansible-playbook -i ansible/inventory/terraform_inventory.ini ansible/install-k8s.yml
    EOT
  }
}