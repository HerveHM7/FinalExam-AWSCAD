# Variables
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "my-finalexam-s3bucket"
}

variable "rds_username" {
  description = "The username for the RDS instance"
  type        = string
  default     = "admin"
}

variable "rds_password" {
  description = "The password for the RDS instance"
  type        = string
  default     = "yourpassword"
}


