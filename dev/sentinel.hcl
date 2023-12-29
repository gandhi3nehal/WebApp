policy "less-than-100-month" {
  enforcement_level = "soft-mandatory"
}

policy "allowed-terraform-version" {
  enforcement_level = "soft-mandatory"
}

policy "restrict-aws-instances-type-and-tag" {
  enforcement_level = "hard-mandatory"
}
