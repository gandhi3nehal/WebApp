
provider "aws" {
  region = "${var.region}"
}

module "compute" {
  source               = "../modules/compute"
  ami                  = "ami-0d70546e43a941d70"
  instance_type        = "t2.micro"
  tag_name             = "${var.env_prefix}-aws-web-app"
  sg                   = module.security.webserver_sg
  user_data            = file("../assets/userdata.tpl")
  iam_instance_profile = module.iam.s3_profile
}

module "security" {
  source = "./module/security"
}

module "iam" {
  source                 = "../modules/iam"
  role_name              = "s3-list-bucket"
  policy_name            = "s3-list-bucket"
  instance_profile_name  = "s3-list-bucket"
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
