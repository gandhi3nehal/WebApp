provider "aws" {
  region = "${var.region}"
}

module "compute" {
  source               = "../modules/compute"
  ami                  = "ami-05fb0b8c1424f266b"
  instance_type        = "${var.instance_type}"
  tag_name             = "${var.env_prefix}-aws-web-app"
  sg                   = module.security.webserver_sg
  user_data            = file("../assets/userdata.tpl")
  iam_instance_profile = module.iam.s3_profile
}

module "security" {
  source = "../modules/security"
  sg_name = "${var.env_prefix}-HTTP-ALB"
}

module "iam" {
  source                 = "../modules/iam"
  role_name              = "${var.env_prefix}-s3-list-bucket"
  policy_name            = "${var.env_prefix}-s3-list-bucket"
  instance_profile_name  = "${var.env_prefix}-s3-list-bucket"
  path                   = "/"
  iam_policy_description = "s3 policy for ec2 to list role"
  iam_policy             = file("../assets/s3-list-bucket-policy.tpl")
  assume_role_policy     = file("../assets/s3-list-bucket-trusted-identity.tpl")
}

module "s3" {
  source        = "../modules/s3"
  bucket_name   = "gnehal-${var.env_prefix}-aws-web-app"
  acl           = "private"
  object_key    = "LUIT"
  object_source = "/dev/null"
}
