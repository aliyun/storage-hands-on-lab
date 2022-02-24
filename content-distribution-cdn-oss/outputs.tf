output "cdn_cname" {
  value = alicloud_cdn_domain_new.cdn_1.cname
  description = "Please set a CNAME record for your domain configured with CDN."
}

output "cdn_domainname" {
  value = alicloud_cdn_domain_new.cdn_1.id
  description = "The domain name that is configured with CDN"
}