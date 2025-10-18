output "vm_static_ips" {
  value = {
    masters = var.master_ip_address
    workers = var.worker_ip_address
  }
}