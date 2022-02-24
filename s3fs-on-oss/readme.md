# OSS Lab 2 - Using S3FS to mount OSS as an ECS volume

##  Description
Lots of applications works directly native file system. S3FS is an open source tool that can mount a S3 compatible storage.
## Architecture
The Terraform script does the following things as shown in the architecture diagram:

![](images/architecture.png) 


### 1. Create OSS bucket for backend storage
```
resource "alicloud_oss_bucket" "default" {
  bucket = var.name
  acl = "private"
  versioning {
    status = "Suspended"
  }
}
```
### 2. Create RAM AK and grant necessary permission to access the OSS bucket

```
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

```

### 3. Create ECS and necessary network components 
```
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

```

### 4. Config S3FS
The script upload the bootstrap bash script to the ECS instance and runs the command. 
```

data "template_file" "user_file" {
template = "${file("./s3fs.sh")}"
  vars = {
    ak = "${alicloud_ram_access_key.ak.id}"
    secret = "${alicloud_ram_access_key.ak.secret}"
    ossbucket = "${alicloud_oss_bucket.default.id}"
    endpoint = "${alicloud_oss_bucket.default.intranet_endpoint}"
  }
}

```
The acutally configuration script is in s3fs.sh file. To run this demo you do not need to change the script.


## Steps to deploy
### install terraform on your local machine
### Run terraform initialization
```
terraform init 
```
### Preview the deployment
```
> terraform plan -var name="<your bucket name>"
```
The command will output resources that are to be created and output otf the script
### Execute the deployment 
```
> terraform apply -var name="<your bucket name>" -auto-approve
```
The script will run for about 10 minutes and output necessary information for testing. At the end of the execution, you should be seeing the following output:" 
### Test with the output
Open your browser and navigate to "nextcloud_ip" in the output, which is the public IP address for your nextcloud server.

### Destroy POC resources
  
Manully delete all the objects in the oss bucket and then run the following:
```
> terraform destropy -var name="<your bucket name>" -auto-approve
```