
locals {
  policies = ["AWSLambdaBasicExecutionRole", "AWSLambdaENIManagementAccess"]
}

# define the iam policy document
data "aws_iam_policy_document" "default" {
  statement {
    sid    = format("%s%sMainPolicyId", var.component, var.env)
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

# define the iam role
resource "aws_iam_role" "default" {
  name               = format("%s-%s-mysql-import-lambda", var.component, var.env)
  assume_role_policy = data.aws_iam_policy_document.default.json
  tags               = var.tags
}


# attach the iam policy to the iam role
resource "aws_iam_role_policy_attachment" "default_policies" {
  for_each   = toset(local.policies)
  policy_arn = "arn:aws:iam::aws:policy/service-role/${each.value}"
  role       = aws_iam_role.default.name
}

# attach the iam policy to the iam role
resource "aws_iam_role_policy_attachment" "attach_iam_rds_policy" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.rds_policy.arn
}

# define the iam policy
resource "aws_iam_policy" "rds_policy" {
  name = format("%s-%s-rds-mysql-import-lambda", var.component, var.env)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:connect",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
  tags = var.tags
}

# generates an archive from content, a file, or a directory of files.
#data "archive_file" "default" {
#  type        = "zip"
#  source_dir  = "${path.module}/function"
#  output_path = "${path.module}/function.zip"
#}

# define the lambda function
resource "aws_lambda_function" "function" {
  filename      = "function.zip"
  architectures = ["arm64"]
  function_name = format("%s-%s-mysql-import", var.component, var.env)
  role          = aws_iam_role.default.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 180
  memory_size   = 128
  #source_code_hash = data.archive_file.default.output_base64sha256
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }
  environment {
    variables = {
      DB_HOST     = var.DB_HOST
      DB_PASSWORD = var.DB_PORT
      DB_USER     = var.DB_USER
      DB_PASSWORD = var.DB_PASSWORD
    }
  }
  # Use the "lifecycle" meta-argument to ensure that the provisioner runs every time the Lambda function changes
  #lifecycle {
  #  create_before_destroy = true
  #}
  depends_on = [
    aws_iam_role_policy_attachment.attach_iam_rds_policy,
    aws_iam_role_policy_attachment.default_policies,
    aws_cloudwatch_log_group.default
  ]
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "default" {
  name              = format("/aws/lambda/%s-%s-mysql-import", var.component, var.env)
  retention_in_days = 1
  tags              = var.tags
}

locals {
  encoded_file = jsonencode({ "base64" = "${base64encode(var.mysql_import_file)}" })
}

#load mysql dump from local  a file
resource "null_resource" "invoke_mysql_import_lambda" {
  count = var.mysql_import_file != "" ? 1 : 0
  provisioner "local-exec" {
    command = "aws lambda invoke --function-name '${split(":", aws_lambda_function.function.arn)[6]}' --cli-binary-format raw-in-base64-out --payload '${local.encoded_file}' /dev/stdout"
  }
  depends_on = [
    aws_lambda_function.function,
    aws_iam_role_policy_attachment.attach_iam_rds_policy,
    aws_iam_role_policy_attachment.default_policies
  ]
}

