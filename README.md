# Instance-Scheduler-AWS
Prerequisites
Terraform: Install Terraform
AWS CLI: Install AWS CLI
AWS Account: Ensure you have sufficient permissions to create IAM roles, DynamoDB tables, CloudWatch Events, and Lambda functions.
Project Overview
This Terraform configuration will:

Create a DynamoDB table to store schedule data.
Set up an IAM Role with permissions for Lambda to manage EC2 instances and access DynamoDB.
Deploy an AWS Lambda function that reads schedules from DynamoDB and starts or stops EC2 instances accordingly.
Set up CloudWatch Events to trigger the Lambda function every hour to check for scheduled instance start/stop actions.
Lambda Function (lambda_function.py)
The lambda_function.py script controls EC2 instances based on schedules stored in DynamoDB. It:

Reads the schedules, which define start and stop hours.
Checks the current hour.
Starts or stops instances if the current hour matches the specified start or stop time.
