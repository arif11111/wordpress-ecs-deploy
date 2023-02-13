############Creating AWS EFS as Persistant Volume for Wordpress data
-------------------

resource "aws_efs_file_system" "wordpress_efs_volume" {
  creation_token = "my-product"
  performance_mode = "maxIO"
  throughput_mode = "bursting"
  tags = {
    Name = "Wordpress-ECS-Fargrate"
  } 
}

resource "aws_security_group" "wordpress_efs_volume_security_group" {
  vpc_id      = aws_vpc.worpress_vpc.id
  ingress {
    from_port   = 2049 # Allowing traffic in from port 80
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }
  
  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_efs_mount_target" "wordpress_mount_target" {
  count = "${length(data.aws_availability_zones.available.names)}"
  file_system_id = aws_efs_file_system.wordpress_efs_volume.id
  subnet_id      = "${aws_subnet.wordpress_public_subnet.id[count.index]}"
  security_groups = "${aws_security_group.wordpress_efs_volume_security_group.id}"
}

resource "aws_efs_access_point" "wordpress_access_point" {
  file_system_id = aws_efs_file_system.wordpress_efs_volume.id
}

