provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "${var.prod_prefix}"
      Service     = "webapp"
    }
  }
}

resource "random_pet" "petname" {
  length    = 3
  separator = "-"
}

resource "aws_s3_bucket" "prod" {
  bucket = "${var.prod_prefix}-${random_pet.petname.id}"

  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "prod" {
  bucket = aws_s3_bucket.prod.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "prod" {
  bucket = aws_s3_bucket.prod.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "prod" {
  bucket = aws_s3_bucket.prod.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_acl" "prod" {
  depends_on = [
    aws_s3_bucket_ownership_controls.prod,
    aws_s3_bucket_public_access_block.prod,
  ]

  bucket = aws_s3_bucket.prod.id

  acl = "public-read"
}

resource "aws_s3_bucket_policy" "prod" {
  depends_on = [
    aws_s3_bucket_acl.prod
  ]

  bucket = aws_s3_bucket.prod.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.prod.id}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_s3_object" "prod" {
  key          = "index.html"
  bucket       = aws_s3_bucket.prod.id
  content      = file("../assets/index.html")
  content_type = "text/html"
}

resource "random_pet" "table_name" {}

resource "aws_dynamodb_table" "table" {
  name = "${var.prod_prefix}-${random_pet.table_name.id}"

  read_capacity  = var.db_read_capacity
  write_capacity = var.db_write_capacity
  hash_key       = "UUID"

  attribute {
    name = "UUID"
    type = "S"
  }
}

resource "aws_iam_role_policy_attachment" "webapp_attachment" {
  role       = aws_iam_role.webapp_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "webapp_profile" {
  name = "${var.prod_prefix}-webapp-profile"
  role = aws_iam_role.webapp_role.name
}

resource "aws_instance" "webapp_instance" {
  ami           = "ami-06ca3ca175f37dd66"
  instance_type = "t2.micro"
  
  iam_instance_profile = aws_iam_instance_profile.webapp_profile.name

  tags = {
    Name = "${var.prod_prefix}-webapp-instance"
  }
}

resource "aws_s3_bucket_policy" "webapp_bucket_policy" {
  bucket = aws_s3_bucket.prod.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.webapp_role.name}"
        },
        "Action": [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::${aws_s3_bucket.prod.id}",
          "arn:aws:s3:::${aws_s3_bucket.prod.id}/*"
        ]
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
