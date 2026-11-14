variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "bedrock-billing"
}

variable "alert_email" {
  description = "Email address for billing alerts"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Must be a valid email address"
  }
}

variable "schedule_expression" {
  description = "EventBridge schedule expression (cron format)"
  type        = string
  default     = "cron(0 8 * * ? *)"  # 8 AM UTC daily
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "lookback_days" {
  description = "Number of days to look back for billing data"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
