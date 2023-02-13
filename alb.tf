########### Creating Aws Elastic Load Balancer for ECS ###########

resource "aws_alb" "application_load_balancer" {
  name               = "wordpress_elb" # Naming our load balancer
  load_balancer_type = "application"
  subnets = "${aws_subnet.wordpress_public_subnet.id}"
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  name     = "load_balancer_security_group"
  vpc_id      = aws_vpc.worpress_vpc.id
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }
  
  ingress {
    from_port   = 443 # Allowing traffic in from port 80
    to_port     = 443
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


resource "aws_lb_target_group" "wordpress_target_group" {
  name     = "wordpress_target_group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.worpress_vpc.id
}

resource "aws_lb_listener" "wordpress_listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}" # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.wordpress_target_group.arn}" # Referencing our tagrte group
  }
}