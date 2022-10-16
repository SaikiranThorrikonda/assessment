import json
import boto3
import string
import random

def lambda_handler(event,context):
    dynamodb = boto3.resource('dynamodb')
    
    client = boto3.client('dynamodb')
    
    S = 10  # number of characters in the string.  
    # call random.choices() string module to find the string in Uppercase + numeric data.  
    ran = ''.join(random.choices(string.ascii_uppercase + string.digits, k = S))    
    print("The randomly generated string is : " + str(ran))
    
    response = client.create_backup(
        TableName='pollinate',
        BackupName=str(ran)
    )
    print('Backup Operation Successful', response)	
    
