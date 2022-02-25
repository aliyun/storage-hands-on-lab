output "fc_endpoint" {
  value = "https://${alicloud_oss_bucket.default.owner}.${var.region}.fc.aliyuncs.com/2016-08-15/proxy/${alicloud_fc_service.default.name}.LATEST/${alicloud_fc_function.default.name}"
}