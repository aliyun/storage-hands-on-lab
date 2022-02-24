# Create a new ECS instance for a VPC
provider "alicloud" {
  region     = "${var.region}"
  profile  = "default"

}

data "template_file" "user_file" {
template = "${file("./s3fs.sh")}"
  vars = {
    ak = "${alicloud_ram_access_key.ak.id}"
    secret = "${alicloud_ram_access_key.ak.secret}"
    ossbucket = "${alicloud_oss_bucket.default.id}"
    endpoint = "${alicloud_oss_bucket.default.intranet_endpoint}"
  }
}

resource "alicloud_security_group" "group" {
  name        = var.name
  description = "security group for next cloud server"
  vpc_id      = alicloud_vpc.default.id
}

# Create a new ECS instance for VPC
resource "alicloud_vpc" "default" {
  vpc_name       = var.name
  cidr_block     = "172.16.0.0/16"
}

data "alicloud_zones" "default" {
  available_disk_category     = "cloud_efficiency"
  available_instance_type     = "ecs.n4.large"
  available_resource_creation = "VSwitch"
}

resource "alicloud_vswitch" "default" {
  vpc_id            = alicloud_vpc.default.id
  cidr_block        = "172.16.0.0/24"
  zone_id           = data.alicloud_zones.default.zones[0].id
  vswitch_name      = var.name
}

resource "alicloud_instance" "instance" {
  image_id          = "ubuntu_20_04_x64_20G_alibase_20211123.vhd"
  vswitch_id        =  alicloud_vswitch.default.id
  security_groups   = [alicloud_security_group.group.id]
  instance_type              = "ecs.n4.large"

  availability_zone = data.alicloud_zones.default.zones[0].id
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "nextcloud_server_systemdisk"
  system_disk_description    = "nextcloud_server_systemdisk"
  instance_name              = var.instance_name
  password                   = var.password
  host_name                  = "s3fstest01"
  user_data = "${data.template_file.user_file.rendered}"
  tags = {
    "used for" : "s3fs poc"
    "oss backend" : "${alicloud_oss_bucket.default.id}"
  }
}

// oss service open
data "alicloud_oss_service" "open" {
  enable = "On"
}

resource "alicloud_oss_bucket" "default" {
  bucket = var.name
  acl = "private"
  versioning {
    status = "Suspended"
  }
}

resource "alicloud_ram_user" "user" {
  name         = var.ram_user_name
  display_name = "s3fs user name"
}

resource "alicloud_ram_access_key" "ak" {
  user_name   = alicloud_ram_user.user.name
}

resource "alicloud_ram_user_policy_attachment" "attach" {
  policy_name = "AliyunOSSFullAccess"
  policy_type = "System"
  user_name   = alicloud_ram_user.user.name
}


resource "alicloud_security_group_rule" "allow_tcp" {
  count = length(var.port_ranges)
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = var.port_ranges[count.index]
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_eip_address" "eip" {
  address_name         = var.name
  payment_type         = "PayAsYouGo"
  internet_charge_type = "PayByBandwidth"
}

resource "alicloud_eip_association" "eip_asso" {
  allocation_id = alicloud_eip_address.eip.id
  instance_id   = alicloud_instance.instance.id
}
