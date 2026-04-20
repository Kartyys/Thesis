provider "aws" {
  region = "eu-north-1"
}

# 1. Skapa själva IAM-rollen för Lambda-funktionen
resource "aws_iam_role" "vulnerable_lambda_role" {
  name = "thesis_vulnerable_lambda_role"

  # Denna del "Endast tjänsten AWS Lambda får lov att använda denna roll"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Skapa säkerhetspolicyn och fäst den på rollen (Det är här felet ligger)
resource "aws_iam_role_policy" "vulnerable_policy" {
  name = "thesis_overly_permissive_policy"
  role = aws_iam_role.vulnerable_lambda_role.id

  # Detta är "The Administrative Wildcard" som RQ1 handlar om
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"   # Tillåter funktionen att göra exakt VAD den vill..
        Resource = "*"   # ..på exakt VILKEN resurs som helst i hela aws kontot.
      }
    ]
  })
}
# 3. Zippa Python-koden (AWS Lambda kräver zip filer)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "vulnerable_lambda.py"
  output_path = "vulnerable_lambda.zip"
}

# 4. Skapa Lambda-funktionen
resource "aws_lambda_function" "vulnerable_function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "thesis_vulnerable_function"
  role             = aws_iam_role.vulnerable_lambda_role.arn
  handler          = "vulnerable_lambda.lambda_handler"
  runtime          = "python3.10" # Välj en modern Python-version
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Detta ger funktionen åtkomst till internet, kan behövas beroende på attack
  environment {
    variables = {
      ENVIRONMENT = "thesis_lab"
    }
  }
}

###############################################################################
# SCENARIO 2: SERVICE-SPECIFIC WILDCARD (S3 FULL ACCESS)
###############################################################################

resource "aws_iam_role" "s3_wildcard_role" {
  name = "thesis_s3_wildcard_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "s3_wildcard_policy" {
  name = "thesis_s3_permissive_policy"
  role = aws_iam_role.s3_wildcard_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:*"
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "s3_function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "thesis_s3_wildcard_function"
  role             = aws_iam_role.s3_wildcard_role.arn
  handler          = "vulnerable_lambda.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

###############################################################################
# SCENARIO 3: STRICTLY LIMITED (LEAST PRIVILEGE)
###############################################################################

resource "aws_iam_role" "limited_role" {
  name = "thesis_strictly_limited_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "limited_policy" {
  name = "thesis_minimal_policy"
  role = aws_iam_role.limited_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_lambda_function" "limited_function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "thesis_strictly_limited_function"
  role             = aws_iam_role.limited_role.arn
  handler          = "vulnerable_lambda.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}