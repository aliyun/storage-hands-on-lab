provider "alicloud" {
  region  = var.region
  profile  = "default"
}

resource "alicloud_oss_bucket" "source_bucket" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "alicloud_oss_bucket_object" "testpic" {
  bucket = "${alicloud_oss_bucket.source_bucket.bucket}"
  key = "testpic.png"
  source = "images/architecture.png"
  acl    = "public-read"
}

resource "alicloud_cdn_domain_new" "cdn_1" {
  cdn_type          = "video"
  domain_name       = var.domain_name
  scope             = var.scope
  tags              = {}

  certificate_config {
    cert_type                 = "free"
    server_certificate_status = "off"
  }

  sources {
    content  = "${alicloud_oss_bucket.source_bucket.bucket}.${alicloud_oss_bucket.source_bucket.extranet_endpoint}"
    port     = 80
    priority = 20
    type     = "oss"
    weight   = 10
  }
}