#creating a Ebs volume
resource "aws_ebs_volume" "data_vol" {
    availability_zone = "us-east-2b"
    size =  2
    tags = {
        Name = "EBS_from_terraform"
    }  
}
 #creating a security group
 resource "aws_security_group" "ssh_http_https_terraform" {
     name = "ssh_http_https"
     description = "used for sshing into an instance"
     #ssh
     ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #HTTP
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }   
 }

 #creating a EC2 - Instance and attaching a security group 
 resource "aws_instance" "instance_with_volume" {
    ami               = "ami-0c3d11a2be38b1c28"
    instance_type     = "t2.micro"
    availability_zone = "us-east-2b"
    #security_groups
    security_groups = [aws_security_group.ssh_http_https_terraform.name]
    tags = {
        Name = "Instance_with_volume_Terraform"
    }
}

#attaching the EBS to the EC2-Instance
resource "aws_volume_attachment" "first-vol" {
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.data-vol.id
  instance_id = aws_instance.instance_with_volume.id
}

#Creating a Network VPC
resource "aws_vpc" "terra_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC-terraform"
  }
}

#Creating a Internet Gateway and attaching it to the VPC
resource "aws_internet_gateway" "terra_igw" {
  vpc_id = aws_vpc.terra_vpc.id

}

variable "subnets_cidr" {
    default = ["10.0.1.0/24"] 
}

variable "azs" {
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

#Creating a subnet and attaching it to a VPC
resource "aws_subnet" "public" {
  count             = length(var.subnets_cidr)
  vpc_id            = aws_vpc.terra_vpc.id 
  cidr_block        = element(var.subnets_cidr, count.index) 
  tags = {
    Name = format("%s%s","subnet",count.index)
  }
  availability_zone = element(var.azs, count.index)
}

#Creating an Eip and associating with an instance
resource "aws_eip" "default" {
    instance = aws_instance.instance_with_volume.id
    vpc      = true
}