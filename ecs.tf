#Creating ECR repo
-------------
resource "aws_ecr_repository" "wordpress_ecr_repo" {
  name = "wordpress_ecr_repo" # Naming my repository
}


#Creating ECS Cluster
--------------
resource "aws_ecs_cluster" "wordpress_cluster" {
  name = "wordpress_cluster" # Naming the cluster
}

#Creating ECS Task DEFINITION
-----------------------
resource "aws_ecs_task_definition" "wp_fargrate_task" {
  family                   = "wp_fargrate_task" 
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my-first-task",
      "image": "${aws_ecr_repository.my_first_ecr_repo.repository_url}",
      "essential": true,
	  "networkMode": "awsvpc", 
      "portMappings": [
        {
          "containerPort": 8080,
        }
      ],
      "mountPoints": [
        {
            "containerPath": "/wp-content/uploads/",
            "sourceVolume": "wordpress"
        }
      ],	  
	  "environment": [
	    {
		  "name": "MARIADB_HOST",
		   "value": "${aws_db_instance.default.endpoint}"
		},
		{
		  "name": "WORDPRESS_DATABASE_NAME"
		  "value": "${aws_db_instance.default.db_name}"
		}
	   ],
	  "secrets": [
	    {
		  "name": WORDPRESS_DATABASE_USER",
		  "valueFrom": "${aws_ssm_parameter.wp_database_username.arn}/database/wordpress/user"
		},
	    {
		  "name": WORDPRESS_DATABASE_PASSWORD",
		  "valueFrom": "${aws_ssm_parameter.wp_database_username.arn}/database/wordpress/passwd"
		},		
	  ]	
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 1024         
  cpu                      = 512         
  name = "${aws_efs_file_system.wordpress_efs_volume.name}"

    efs_volume_configuration {
      file_system_id          = "${aws_efs_file_system.wordpress_efs_volume.id}"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = "${aws_efs_file_system.wordpress_access_point.id}"
        iam             = "ENABLED"
      }
    }
  }  
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

#Creating ECS Repo
resource "aws_ecs_service" "wp_service" {
  name            = "wp_service"
  cluster         = "${aws_ecs_cluster.wordpress_cluster.id}"
  task_definition = "${aws_ecs_task_definition.wp_fargrate_task.arn}"
  launch_type     = "FARGATE"
  desired_count   = 3 
  
  load_balancer {
    target_group_arn = "${aws_lb_target_group.wordpress_target_group.arn}" # Referencing our ELB target group
    container_name   = "${aws_ecs_task_definition.wp_fargrate_task.family}"
    container_port   = 8080 # Specifying the container port
  }
  
  deployment_controller {
    type = "CODE_DEPLOY"
  }  
  
  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true # Providing our containers with public IPs
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


data "aws_iam_policy_document" "ECSreqaccess" {

  statement {
    sid    = "AllowECR"
    effect = "Allow"

    actions = [
      "ecr:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AWSSMparameteres"
    effect = "Allow"

    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]

    resources = [
	"${aws_ssm_parameter.wp_database_username.arn}",
	"${aws_ssm_parameter.wp_database_passwd.arn}"
	]
  }

  statement {
    sid       = "AllowRDStoECS"
    effect    = "Allow"
    actions   = ["rds-db:connect",]
    resources = ["${aws_db_instance.default.arn}"]
  }

  statement {
    sid    = "AllowLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ECSreqaccess" {
  role   = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy = "${data.aws_iam_policy_document.ECSreqaccess.json}"
}






