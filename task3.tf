// mention IAM user in profile
provider "aws" {
  region = "ap-south-1"
  profile = "<IAM User>"
}

# Creating VPC
resource "aws_vpc" "task3-vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "task3-vpc" 
  }
}

# Creating Public Subnet for Wordpress
resource "aws_subnet" "task3-public-wp" {
  depends_on = [
    aws_vpc.task3-vpc,
  ]
  
  vpc_id = aws_vpc.task3-vpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "public-wp"
  }
}

# Creating Private Subnet for MySQL Database
resource "aws_subnet" "task3-private-db" {
  depends_on = [
    aws_vpc.task3-vpc,
  ]
  
  vpc_id = aws_vpc.task3-vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = false
  tags = {
    "Name" = "private-db"
  }
}

# Creating Internet Gateway for wordpress vpc
resource "aws_internet_gateway" "task3-wp-ig" {
  depends_on = [
    aws_vpc.task3-vpc,
  ]
  
  vpc_id = aws_vpc.task3-vpc.id
  tags = {
    "Name" = "task3-wp-ig"
  }
}

# route table attach to our internet gateway
resource "aws_route_table" "task3-rt" {
  depends_on = [
    aws_internet_gateway.task3-wp-ig,
  ]

  vpc_id = aws_vpc.task3-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.task3-wp-ig.id
  }

  tags = {
    Name = "my-routing-table"
  }
}

# route table connect to public subnet
resource "aws_route_table_association" "task3-rt-ascn" {
  depends_on = [
    aws_route_table.task3-rt,
    aws_subnet.task3-public-wp,
  ]

  subnet_id = aws_subnet.task3-public-wp.id
  route_table_id = aws_route_table.task3-rt.id
}

# security group for Wordpress
resource "aws_security_group" "task3-sg-wp" {
  depends_on = [
    aws_vpc.task3-vpc,
  ]

  name        = "SG-Wordpress"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.task3-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wp-sg"
  }
}

# security group for MySQL DB
resource "aws_security_group" "task3-sg-db" {
  depends_on = [
    aws_vpc.task3-vpc,
    aws_security_group.task3-sg-wp,
  ]

  name        = "SG-Database"
  description = "Allow SG-Wordpress inbound traffic"
  vpc_id      = aws_vpc.task3-vpc.id

  ingress {
    description = "MySQL"
    security_groups = [
      aws_security_group.task3-sg-wp.id,
    ]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

# MySQL instance
resource "aws_instance" "task3-mysql" {
  depends_on = [
    aws_security_group.task3-sg-db,
    aws_subnet.task3-private-db,
  ]

  ami = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  associate_public_ip_address = false
  subnet_id = aws_subnet.task3-private-db.id
  vpc_security_group_ids = [
    aws_security_group.task3-sg-db.id,
  ]

  tags ={
    Name = "task3-mysql"
  }
}

resource "aws_instance" "task3-wordpress" {
  depends_on = [
    aws_subnet.task3-public-wp,
    aws_security_group.task3-sg-wp,
  ]

  // ami = "ami-0447a12f28fddb066"
  ami = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.task3-public-wp.id
  vpc_security_group_ids = [
    aws_security_group.task3-sg-wp.id,
  ]
  key_name = "<specify key to use/created"

  tags ={
    Name = "task3-wordpress"
  }
}
