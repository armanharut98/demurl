import { DynamoDBClient, GetItemCommand } from "@aws-sdk/client-dynamodb";

const region = process.env.REGION
const client = new DynamoDBClient({
    region
})

const tableName = process.env.TABLE_NAME

export const handler = async (event) => {
    console.log(JSON.stringify(event))
    const params = {
        TableName: tableName,
        Key: {
            id: {
                S: event.id
            }
        }
    }
    const command = new GetItemCommand(params)
    try {
        const response = await client.send(command)
        return {
            statusCode: 301,
            headers: {
                Location: response.Item.url.S
            }
        }
    } catch (exception) {
        console.log("Error: ", exception)
    }
}
