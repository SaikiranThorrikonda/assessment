import time
import json
import boto3

def lambda_handler(event,context):
    dynamodb = boto3.resource('dynamodb')
    
#function definition
def lambda_handler(event,context):
    dynamodb = boto3.resource('dynamodb')
    
    #table created with table name
    table = dynamodb.Table('pollinate') 
    
	#time and date functions
    named_tuple = time.localtime() # get struct_time
    time_string = time.strftime("%m/%d/%Y, %H:%M:%S", named_tuple)
	
    print("Execution Successful...!", time_string)
    
    #inserting values into table with key-value pair
    response = table.put_item(
       Item={
            'date_time': str(time_string),
            
        }
    )
    return response

