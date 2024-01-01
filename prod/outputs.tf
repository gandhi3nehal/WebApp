output "public_ip" {
  value = "http://${module.compute.public_ip}"
}
