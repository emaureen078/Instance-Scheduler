import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
ec2 = boto3.client('ec2')
table_name = os.environ['DYNAMODB_TABLE']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    current_hour = datetime.now().hour
    instances_to_start = []
    instances_to_stop = []
    
    # Scan DynamoDB to get all schedules
    response = table.scan()
    for schedule in response['Items']:
        start_hour = int(schedule['start_hour'])
        stop_hour = int(schedule['stop_hour'])
        
        if current_hour == start_hour:
            instances_to_start.extend(schedule['instance_ids'])
        elif current_hour == stop_hour:
            instances_to_stop.extend(schedule['instance_ids'])
    
    # Start instances
    if instances_to_start:
        ec2.start_instances(InstanceIds=instances_to_start)
    
    # Stop instances
    if instances_to_stop:
        ec2.stop_instances(InstanceIds=instances_to_stop)
    
    return {
        'statusCode': 200,
        'body': 'Instances scheduled successfully.'
    }
