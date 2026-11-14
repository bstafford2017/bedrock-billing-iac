import boto3
import json
import os
from datetime import datetime, timedelta

ce_client = boto3.client('ce', region_name=os.environ['AWS_REGION'])
sns_client = boto3.client('sns', region_name=os.environ['AWS_REGION'])

def handler(event, context):
    """
    Lambda handler to fetch Bedrock billing data and send email alert
    """
    try:
        # Get yesterday's date for billing query
        today = datetime.utcnow().date()
        yesterday = today - timedelta(days=1)
        
        # Format dates for Cost Explorer API
        start_date = yesterday.strftime('%Y-%m-%d')
        end_date = today.strftime('%Y-%m-%d')
        
        print(f"Fetching Bedrock billing data for: {start_date} to {end_date}")
        
        # Query Cost Explorer for Bedrock costs
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date,
                'End': end_date
            },
            Granularity='DAILY',
            Filter={
                'Dimensions': {
                    'Key': 'SERVICE',
                    'Values': ['Amazon Bedrock']
                }
            },
            Metrics=['UnblendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'USAGE_TYPE'
                }
            ]
        )
        
        # Parse billing data
        total_cost = 0.0
        usage_details = []
        
        if 'ResultsByTime' in response and len(response['ResultsByTime']) > 0:
            for result in response['ResultsByTime']:
                for group in result.get('Groups', []):
                    usage_type = group['Keys'][0]
                    cost = float(group['Metrics']['UnblendedCost']['Amount'])
                    total_cost += cost
                    usage_details.append({
                        'usage_type': usage_type,
                        'cost': cost
                    })
        
        # Format email message
        message = format_billing_email(total_cost, usage_details, start_date, end_date)
        
        # Send SNS notification
        sns_client.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject=f"Bedrock Daily Billing Alert - {yesterday.strftime('%Y-%m-%d')}",
            Message=message
        )
        
        print(f"Billing alert sent successfully. Total cost: ${total_cost:.2f}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Billing report sent',
                'total_cost': total_cost,
                'date': str(yesterday)
            })
        }
        
    except Exception as e:
        error_message = f"Error fetching Bedrock billing: {str(e)}"
        print(error_message)
        
        # Send error notification
        sns_client.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject="Bedrock Billing Alert - ERROR",
            Message=f"Failed to retrieve billing data:\n{error_message}"
        )
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_message})
        }

def format_billing_email(total_cost, usage_details, start_date, end_date):
    """
    Format the billing email with detailed information
    """
    email_body = f"""
Bedrock Billing Summary Report
==============================

Period: {start_date} to {end_date}
Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}

Total Cost: ${total_cost:.4f}

Breakdown by Usage Type:
------------------------
"""
    
    if usage_details:
        for detail in sorted(usage_details, key=lambda x: x['cost'], reverse=True):
            email_body += f"\n{detail['usage_type']}: ${detail['cost']:.4f}"
    else:
        email_body += "\nNo Bedrock usage detected"
    
    email_body += """

Notes:
------
- Costs shown are UnblendedCost (your actual charges)
- This report is generated daily at 8 AM UTC
- For detailed breakdowns, visit the AWS Cost Explorer console
- Charges may take up to 24 hours to appear in billing data

Cost Explorer: https://console.aws.amazon.com/cost-management/home?region=us-east-1#/custom

---
This is an automated alert. Do not reply to this email.
"""
    
    return email_body
