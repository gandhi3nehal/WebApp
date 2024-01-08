variable "region" {
  description = "This is the cloud hosting region where your webapp will be deployed."
  default      = "us-east-1"
}

variable "env_prefix" {
  description = "This is the environment where your webapp is deployed. qa, prod, or dev"
  default  = "prod"
}

variable "instance_type" {
  description = "instance type"
  default  = "t2.small"
}

variable "key_pair" {
  description = "key pair"
  default  = "us-east-1-key"
}

variable "ami" {
  description = "ami"
  default  = "ami-0005e0cfe09cc9050"
}
