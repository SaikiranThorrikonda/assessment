Create an IAM Role for Lambda:
==========================

IAM  Roles  Create role
Add permissions policies  AmazonDynamoDBFullAccess
{Note: In Production Environment, always prefer least access privileges only and also add tags for resources}
Role name: “lambda_dynamodb”



Create Lambda for date_time on DynamoDB:
=====================================

Lambda  Create Function  Function name: “datetime_lambda”  Runtime: Python 3.9
Change Default execution role  Use an existing role  Select the create role “lambda_dynamodb”
Create Function.  datetime_lambda



Create DynamoDB Table to store date_time:
=====================================

DynamoDB  Create Table  Table name: “pollinate” 
Partition key  “date_time”
Create Table with Default Settings.

Configure API Gateway:
===================

API Gateway  HTTP API  Build
Integration  Add Integration  Lambda  Select Lambda Function “datetime_lambda”
API name  “datetimelog”
Method  Select POST {As per Pollinate Technical Assessment Requirements}

 

Test the API Endpoint with Curl Command:
===================================

Command:
Curl -X POST https://2gh8ll9ay2.execute-api.us-east-2.amazonaws.com/datetime


Create Lambda for DB Backup:
=========================

Lambda  Create Function  Function name: “backupdb_lambda”  Runtime: Python 3.9
Change Default execution role  Use an existing role  Select the create role “lambda_dynamodb”
Create Function.  backupdb_lambda


Automate Backup Operation with CloudWatch Event:  {Interval = 5 min}
============================================

Note: We can alternatively Automate DynamoDB Table backup using AWS Backup.
CloudWatch  Events  Rules  Create rule
Event Source  Schedule  Fixed rate of  1 min
Targets  Add target  Select the DB backup lambda function i.e, “backupdb_lambda”
 
Enable/Disable this Event to Enable/Disable the DynamoDB Table Backup Operation.


Creating Cloudwatch Dashboard for Lambda Functions:
==============================================
CloudWatch  Dashboards  Create Dashboard  Name the Dashboard
Add Widget  Select Explorer  “Single Widget with multiple tag-based graphs”
Choose “Pre-filled Explorer widget”  Choose Template  Lambda by runtime



