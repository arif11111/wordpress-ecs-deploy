##############AWS RDS instance creation ############






resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "wordpress"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "admin1234"
  db_subnet_group_name =  "${aws_db_subnet_group.wordpress_db_subnet_group.id}"
  vpc_security_group_ids = ["${aws_security_group.wordpress_db_security_group.id}"]
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_db_subnet_group" "wordpress_db_subnet_group" {
  name       = "wordpress_db_subnet_group"
  subnet_ids = "${aws_subnet.wordpress_public_subnet.id}"
  tags = {
    ${var.tags}
  }
}

resource "aws_security_group" "wordpress_db_security_group" {
  ingress {
    from_port   = 3306 # Allowing traffic in from port 80
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.90.0.0/16"] # Allowing traffic in from all sources
  }
  
  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}


resource "aws_ssm_parameter" "wp_database_username" {
    name        = "/database/wordpress/user"
    description = "Production environment database password"
    type        = "SecureString"
    value       = "${ var.wp_db_username }"
}


resource "aws_ssm_parameter" "wp_database_passwd" {
    name        = "/database/wordpress/user"
    type        = "SecureString"
    value       = "${ var.wp_db_password }"
}

esource "aws_iam_role_policy" "password_policy_parameterstore" {
  name = "password-policy-parameterstore"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ssm:GetParameters"
        ],
        "Effect": "Allow",
        "Resource": [
          "${aws_ssm_parameter.database_password_parameter.arn}"
        ]
      }
    ]
  }
  EOF
}
