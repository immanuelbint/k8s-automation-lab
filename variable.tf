variable "libvirt_pool_name" {
    description = "KVM storage pool"
    default     = "pool-1"
}

variable "base_image_path" {
    description = "images path to be used by virtual machine"
    type        = string
    default     = "/data/images/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2"
}

variable "vm_domain" {
    description = "domain for virtual machine"
    default     = "example.com"
}

variable "ssh_username" {
  description = "the ssh user to use"
  default     = "abint"
}

variable "ssh_private_key" {
  default = "~/.ssh/id_ed25519"
}

# --- Master node variable --- #

variable "master_hostname" {
    description = "vm master hostname"
    default     = "masternode"
}

variable "master_cpu" {
    description = "number of CPU cores for the master virtual machine"
    type        = number
    default     = 1
}

variable "master_memory" {
    description = "memory size for the master virtual machine in MB"
    type        = number
    default     = 4096
}

variable "master_ip_address" {
    type        = list(string)
    description = "IP Addresses to be used by master virtual machine (with CIDR)"
    default     = ["192.168.122.2"]
}

variable "master_count" {
    description = "Number of master VMs to create"
    default     = 1
}

variable "master_data_volume" {
    description = "Additional data volume config to be used by virtual machine"
    type        = list(object({
        name    = string
        pool    = string
        size    = number
        format  = string
    }))
    default     = [
        {
            name    = "master-data-vol"
            pool    = "pool-1"
            size    = 50
            format  = "qcow2"
        }
    ]
}

# --- Worker node variable --- #

variable "worker_hostname" {
    description = "vm worker hostname"
    default     = "workernode"
}

variable "worker_cpu" {
    description = "number of CPU cores for the worker virtual machine"
    type        = number
    default     = 1
}

variable "worker_memory" {
    description = "memory size for the worker virtual machine in MB"
    type        = number
    default     = 4096
}

variable "worker_ip_address" {
    type        = list(string)
    description = "IP Addresses to be used by worker virtual machine (with CIDR)"
    default     = ["192.168.122.3", "192.168.122.4"]
}

variable "worker_count" {
    description = "Number of worker VMs to create"
    default     = 2
}

variable "worker_data_volume" {
    description = "Additional data volume config to be used by virtual machine"
    type        = list(object({
        name    = string
        pool    = string
        size    = number
        format  = string
    }))
    default     = [
        {
            name    = "data-vol"
            pool    = "pool-1"
            size    = 50
            format  = "qcow2"
        }
    ]
}
