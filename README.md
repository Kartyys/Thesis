# Security Analysis of IAM Policy Misconfigurations in Serverless Architectures

This repository contains the source code and configuration files used for my degree project at Blekinge Institute of Technology (BTH). The project investigates the "blast radius" of different IAM wildcard configurations in AWS Lambda and evaluates the effectiveness of automated static analysis.

## Repository Contents

* **main.tf**: Terraform configuration that provisions three different IAM scenarios (Full Admin, S3 Wildcard, and Least Privilege).
* **vulnerable_lambda.py**: The Python source code for the AWS Lambda function, containing an intentional command injection vulnerability for testing purposes.
* **checkov_results.txt**: The full output from a Checkov static analysis scan performed on the infrastructure.

## How to Reproduce

### 1. Provision the environment
Ensure you have AWS credentials configured and Terraform installed.

```bash
terraform init
terraform apply
```

### 2. Run Automated Scan
To see the security warnings identified in the thesis:

```bash
checkov -f main.tf
```

### 3. Manual Exploitation
Invoke the Lambda function with a payload to extract environment variables:

```bash
aws lambda invoke --function-name <function_name> --payload '{"command": "env"}' out.json
```

## Disclaimer
**This project is for educational and research purposes only.** The code intentionally introduces critical security vulnerabilities. Do not deploy this configuration in a production environment or any account containing sensitive data.
