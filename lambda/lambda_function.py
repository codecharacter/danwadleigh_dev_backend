import boto3
import simplejson as json

# Connect to DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('danwadleigh-dev-counter')


def lambda_handler(event, context):
    http_method = event['httpMethod']

    if http_method == 'OPTIONS':
        # Handle CORS configuration
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization'
            }
        }
    if http_method == 'GET':
        try:
            # Update the visitor_count in DynamoDB
            response = table.update_item(
                Key={"id": "counter"},
                ExpressionAttributeValues={":inc": 1},
                UpdateExpression="SET visitor_count = visitor_count + :inc",
                ReturnValues="UPDATED_NEW"
            )
            updated = response['Attributes']['visitor_count']         
            # Return visitor_count directly in the response body
            return {
                'statusCode': 200,
                'body': json.dumps(updated),
                'headers': {
                    'Content-Type': 'application/json'
                }
            }
        except Exception as e:
            return {
                'statusCode': 500,
                'body': json.dumps({'error': str(e)})
            }
