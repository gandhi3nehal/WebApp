variable "region" {
  description = "This is the cloud hosting region where your webapp will be deployed."
  region      = "us-east-2"
}

variable "dev_prefix" {
  description = "This is the environment where your webapp is deployed. qa, prod, or dev"
  dev_prefix  = "dev"
}

variable "db_read_capacity" {
  type = number
}

variable "db_write_capacity" {
  type = number
}
