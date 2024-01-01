# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "public-ip" {
  value = aws_eip.production-eip.public_ip
}
