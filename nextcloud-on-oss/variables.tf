variable "name" {
  description = "Name for your deployment. It will be also used for your oss bucket. Specify a unique valueu."
  type        = string
}

variable "region" {
  description = "region of the deployment."
  type        = string
 //default = "cn-hangzhou"
 default = "ap-southeast-1"
}

variable "instance_name" {
  description = "Name of your ECS instance for next cloud server"
  type        = string
  default     = "nextcloud_poc_server_01"
}

variable "password" {
  description = "The password for next cloud server."
  type        = string
  default = "Quattro!"
}


variable "port_ranges" {
  description = "Security Group rules.These ports are open for POC."
  type        = list(string)
  default     = ["22/22","80/80","443/443"]
}

variable "ram_user_name" {
  description = "name of RAM user used for next cloud server accessing OSS."
  type        = string
  default     = "nextcloud_user_02"
}
