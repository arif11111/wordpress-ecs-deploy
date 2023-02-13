
######Creating AWS VPC and Public Subnet Configuration for Wordpress Region ####
resource "aws_vpc" "wordpress_vpc" {
  cidr_block       = "10.90.0.0/16"
  instance_tenancy = "default"

  tags = {
    ${var.tags}
  }
}

resource "aws_subnet" "wordpress_public_subnet" {
  count = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.worpress_vpc.id}"
  cidr_block = "10.90.${10+count.index}.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true
  tags {
   ${var.tags}
  }
}


resource "aws_internet_gateway" "wordpress-gw" {
  vpc_id = aws_vpc.worpress_vpc.id

  tags = {
    ${var.tags}
  }
}

resource "aws_internet_gateway_attachment" "wordpress-gw-attachment" {
  internet_gateway_id = aws_internet_gateway.wordpress-gw.id
  vpc_id              = aws_vpc.worpress_vpc.id
}


resource "aws_route_table" "wordpress-routetable" {
  vpc_id = aws_vpc.worpress_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress-gw.id
  }

  tags = {
    ${var.tags}  
	}
}

resource "aws_route_table_association" "wp_rta" {
  count = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${aws_subnet.wordpress_public_subnet.id[count.index]}"
  route_table_id = aws_route_table.bar.id
}


resource "aws_network_acl" "wordpress-acl" {
  vpc_id = aws_vpc.worpress_vpc.id

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    ${var.tags}  
	}
}

resource "aws_network_acl_association" "wp-nacl_association" {
  count = "${length(data.aws_availability_zones.available.names)}"
  network_acl_id = aws_network_acl.wordpress-acl.id
  subnet_id      = "${aws_subnet.wordpress_public_subnet.id[count.index]}"
}









