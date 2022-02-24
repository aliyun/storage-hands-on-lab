output "instance_id" {
  value = alicloud_instance.instance.id
}

output "ssh_to" {
  value = "ssh root@${alicloud_eip_address.eip.ip_address}"
}

output "zones_id" {
  value = data.alicloud_zones.default.zones[0].id
}

output "oss_share_directory"{
  value = "/tmp/s3fs"
}

output "oss_bucket" {
  value = alicloud_oss_bucket.default.id
}

