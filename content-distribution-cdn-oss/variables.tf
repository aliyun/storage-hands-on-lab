variable "region" {
  description = "Region for this deployment. Use any valid region code for Alibaba Cloud."
  default = "ap-southeast-1"
}

variable "domain_name" {
  description = "The domain name for your website. You must own this domain name."
  type        = string
  default     = "example3.com"
}

variable "scope" {
  description = "Use overseas to distribute content to regions outside of mainland China."
  type        = string
  default     = "overseas"
}

variable "bucket_name" {
  description = "Name of your OSS bucket. Please Use lower case. The bucket name must be unique."
  type        = string
}
