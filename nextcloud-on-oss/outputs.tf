output "nextcloud_server_instance_id" {
  value = alicloud_instance.instance.id
}
output "nextcloud_server_zone_id" {
  value = data.alicloud_zones.default.zones[0].id
}

output "ssh_to_nextcloud_server" {
  value = "ssh root@${alicloud_eip_address.eip.ip_address}"
}

output "nextcloud_oss_bucket" {
  value = alicloud_oss_bucket.default.id
}

output "nextcloud_ip" {
  value = "http://${alicloud_eip_address.eip.ip_address}"
}