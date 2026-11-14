terraform {
  required_version = ">= 1.0"
}

# Archive Python Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# This ensures the zip file is created before Lambda function
output "lambda_zip_path" {
  value = data.archive_file.lambda_zip.output_path
}
