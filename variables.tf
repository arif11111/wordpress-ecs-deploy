provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-2" # Setting my region to London. Use your own region here
}

variable vpc_subnet {
  default = "10.90.0.0/16"
}

variable tags {
  type = map

  default = {
    "Product" = "Wordpres-demo"
  }
}

data "aws_availability_zones" "available" {}


resource "aws_vpc" "worpress_vpc" {
  cidr_block       = "${ var.vpc_subnet }"
  instance_tenancy = "default"

  tags = {
    ${var.tags}
	Network = Public
	
  }
}


variable "wp_db_secret" {
  default = {
    WORDPRESS_DATABASE_USER = "admin"
    WORDPRESS_DATABASE_PASSWORD = "supersecretpassword"
  }

  type = map(string)
}


variable wp_db_username {
  default = "admin"
}

variable wp_db_password {
  default = "admin1234"
}
