import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import crc32 from 'crc/crc32';

const region = process.env.REGION
const client = new DynamoDBClient({
    region
})

const tableName = process.env.TABLE_NAME

export const handler = async (event) => {
    console.log(JSON.stringify(event))
    const hash = crc32(event.body.url).toString(16)
    const params = {
        TableName: tableName,
        Item: {
            "id": { "S": hash.toString() },
            "url": { "S": event.body.url }
        }
    }
    const command = new PutItemCommand(params)
    try {
        await client.send(command)
        return {
            statusCode: 201,
            headers: {
                "Content-Type": "application/json"
            },
            body: {
                hash
            }
        }
    } catch (exception) {
        console.log("Error: ", exception)
    }
}

