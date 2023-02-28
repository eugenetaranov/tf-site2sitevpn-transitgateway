variable "az" {
  default = ["a", "b", "c"]
}

variable "region" {
  default = "us-east-1"
}

variable "testvpc_a_cidr" {
  default = "10.50.0.0/16"
}

variable "testvpc_b_cidr" {
  default = "10.60.0.0/16"
}
