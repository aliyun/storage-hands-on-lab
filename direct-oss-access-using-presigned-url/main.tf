provider "alicloud" {
  region     = "${var.region}"
  profile  = "default"
}

//fc 
resource "alicloud_log_project" "default" {
  name        = var.name
  description = "fc_log"
}

resource "alicloud_log_store" "default" {
  project          = alicloud_log_project.default.name
  name             = var.name
  retention_period = "3000"
  shard_count      = 1
}

resource "alicloud_fc_service" "default" {
  name        = var.name
  description = "fc_service_presignedurl"
  log_config {
    project  = alicloud_log_project.default.name
    logstore = alicloud_log_store.default.name
  }
  role       = alicloud_ram_role.default.arn
  depends_on = [alicloud_ram_role_policy_attachment.default]
}

resource "alicloud_ram_role" "default" {
  name        = var.name
  document    = <<EOF
        {
          "Statement": [
            {
              "Action": "sts:AssumeRole",
              "Effect": "Allow",
              "Principal": {
                "Service": [
                  "fc.aliyuncs.com"
                ]
              }
            }
          ],
          "Version": "1"
        }

EOF
  description = "this is a test"
  force       = true
}

resource "alicloud_ram_role_policy_attachment" "default" {
  role_name   = alicloud_ram_role.default.name
  policy_name = "AliyunLogFullAccess"
  policy_type = "System"
}

resource "alicloud_fc_function" "default" {
  service     = alicloud_fc_service.default.name
  name        = var.name
  description = "tf"
  filename = "./getpresignedurl-code.zip"
  memory_size = "512"
  runtime     = "nodejs12"
  handler     = "index.handler"
  environment_variables = {
    ak = alicloud_ram_access_key.ak.id
    sk = alicloud_ram_access_key.ak.secret
    bucketname = alicloud_oss_bucket.default.id
    endpoint =  alicloud_oss_bucket.default.extranet_endpoint
  }
}

resource "alicloud_fc_trigger" "default" {
  service    = "${alicloud_fc_service.default.name}"
  function   = "${alicloud_fc_function.default.name}"
  name       = "${var.name}"
  type       = "http"
  config     =  local.http_trigger_conf
}

resource "alicloud_oss_bucket" "default" {
  bucket = var.bucketname
  acl = "private"
}


resource "alicloud_ram_user" "user" {
  name         = "oss_access_${var.bucketname}"
  display_name = "fc access bucket ${var.bucketname}"
}

resource "alicloud_ram_access_key" "ak" {
  user_name   = alicloud_ram_user.user.name
}

resource "alicloud_ram_policy" "fc_access_oss_policy" {
  policy_name        = "fc_access_${var.bucketname}"
  policy_document    = <<EOF
  {
    "Statement": [
      {
        "Action": [
          "oss:ListObjects",
          "oss:GetObject",
          "oss:PUTObject"
        ],
        "Effect": "Allow",
        "Resource": [
          "acs:oss:*:*:${alicloud_oss_bucket.default.id}",
          "acs:oss:*:*:${alicloud_oss_bucket.default.id}/*"
        ]
      }
    ],
      "Version": "1"
  }
  EOF
  description = "Allow Object Operation for bucket ${alicloud_oss_bucket.default.id}"
  force       = true
}

resource "alicloud_ram_user_policy_attachment" "attach" {
  policy_name = alicloud_ram_policy.fc_access_oss_policy.name
  policy_type = alicloud_ram_policy.fc_access_oss_policy.type
  user_name   = alicloud_ram_user.user.name
}