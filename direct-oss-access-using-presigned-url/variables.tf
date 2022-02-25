
variable "region" {
  description = "region of the deployment."
  type        = string
  default = "cn-hangzhou"
}

variable "name" {
  default = "alicloudfcfunctionconfig"
}

variable "ram_user_name" {
  default = "fc_access_oss"
}

variable "bucketname" {
  default = "presignedurldemo0001"
}
