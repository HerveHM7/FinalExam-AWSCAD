terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

# Data Source for Existing VPC
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "cidr-block"
    values = ["10.50.0.0/16"]
  }
}

# S3 Bucket
resource "aws_s3_bucket" "my-finalexam-s3bucket" {
  bucket = var.bucket_name
}

# IAM Role and Policy
resource "aws_iam_role" "glue_role" {
  name = "glue_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com", "glue.amazonaws.com"]
        }
      }
    ]
  })
}

resource "aws_iam_policy" "glue_policy" {
  name        = "glue_policy"
  description = "Policy for Glue job and EC2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.my-finalexam-s3bucket.arn}/*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}

# Security Group
resource "aws_security_group" "rds_security_group" {
  name        = "new_rds_security_group"
  description = "Security group for RDS MySQL"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow MySQL access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB Subnet Group (Using your provided subnet IDs)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = ["subnet-002571a3a2ff205c4", "subnet-0dc6f36638ff262fe"]

  tags = {
    Name = "My RDS Subnet Group"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "mysql_instance" {
  identifier              = "mysql-instance"
  allocated_storage       = 20  
  engine                 = "mysql"
  engine_version         = "8.0" 
  instance_class         = "db.t3.micro"
  db_name                = "finalexamdb"  
  username               = var.rds_username
  password               = var.rds_password
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name  # Reference the new subnet group
  skip_final_snapshot    = true
}

# Create a AWS Glue Job
resource "aws_glue_job" "glue_job" {
  name     = "my_glue_job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.my-finalexam-s3bucket.bucket}/glue_script.py"
    python_version  = "3"
  }
}

# Create a KMS Key
resource "aws_kms_key" "kms_key" {
  description             = "KMS key for encryption"
  deletion_window_in_days = 10
}

# Create an Application Load Balancer
resource "aws_lb" "alb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.rds_security_group.id]
  subnets            = ["subnet-002571a3a2ff205c4", "subnet-0dc6f36638ff262fe"] # Replace with your subnet IDs
}

# Create an AutoScaling Group
resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.launch_config.name
  vpc_zone_identifier  = ["subnet-002571a3a2ff205c4", "subnet-0dc6f36638ff262fe"] # Replace with your subnet IDs
  max_size             = 5
  min_size             = 1
  desired_capacity     = 1

  tag {
    key                 = "Name"
    value               = "my_asg_instances"
    propagate_at_launch = true
  }
}

# Launch Configuration for the AutoScaling Group
resource "aws_launch_configuration" "launch_config" {
  name_prefix     = "my_launch_config-"
  image_id        = "ami-0c2489d63913b3b1f" # Replace with your AMI ID
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.rds_security_group.id]

  lifecycle {
    create_before_destroy = true
  }
}



