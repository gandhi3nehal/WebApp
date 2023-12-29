variable "region" {
  description = "This is the cloud hosting region where your webapp will be deployed."
  region      = "us-east-2"
}

variable "prod_prefix" {
  description = "This is the environment where your webapp is deployed. qa, prod, or dev"
  prod_prefix = "prod"
}

variable "db_read_capacity" {
  type = number
}

variable "db_write_capacity" {
  type = number
}
