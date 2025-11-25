# WeatherServiceQueue Function

A queue-triggered Azure Function that generates random weather data for specified locations. The function reads weather requests from an input queue, generates a random temperature, and writes the response to an output queue.

## Function Overview

- **Trigger**: Azure Storage Queue
- **Input Queue**: `tool-input`
- **Output Queue**: `tool-output`
- **Function Name**: `WeatherServiceQueue`

## How It Works

1. A message containing a location and correlation ID is placed in the input queue
2. The function is triggered and processes the request
3. A random temperature between -15°C and 45°C is generated for the location
4. The weather response is written to the output queue with the correlation ID

## Message Format

### Input Message (to `tool-input` queue)

```json
{
  "Location": "Berlin",
  "CorrelationId": "12345678-1234-1234-1234-123456789abc"
}
```

### Output Message (from `tool-output` queue)

```json
{
  "Location": "Berlin",
  "Temperature": 23,
  "Unit": "Celsius",
  "CorrelationId": "12345678-1234-1234-1234-123456789abc"
}
```

## Using the Function with Azure CLI

### Prerequisites

- Azure CLI installed ([Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- Access to an Azure subscription
- Storage account with queues created

### 1. Login to Azure

```bash
az login
```

If you have multiple subscriptions, set the active one:

```bash
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Set Variables

```bash
# Replace with your actual values
RESOURCE_GROUP="rg-agent-test"
STORAGE_ACCOUNT="mkagentstorage"
INPUT_QUEUE="tool-input"
OUTPUT_QUEUE="tool-output"
```

### 3. Get Storage Account Connection String

```bash
CONNECTION_STRING=$(az storage account show-connection-string \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --query connectionString \
  --output tsv)
```

### 4. Send a Message to Input Queue

```bash
# Create a sample message
MESSAGE='{
  "Location": "Berlin",
  "CorrelationId": "12345678-1234-1234-1234-123456789abc"
}'

# Send message to input queue
az storage message put \
  --queue-name $INPUT_QUEUE \
  --content "$MESSAGE" \
  --connection-string "$CONNECTION_STRING"
```

### 5. Read Messages from Output Queue

Wait a few seconds for the function to process, then read from the output queue:

```bash
# Peek at messages (doesn't remove them)
az storage message peek \
  --queue-name $OUTPUT_QUEUE \
  --num-messages 5 \
  --connection-string "$CONNECTION_STRING"

# Get and remove messages
az storage message get \
  --queue-name $OUTPUT_QUEUE \
  --num-messages 1 \
  --connection-string "$CONNECTION_STRING"
```

## Sample Messages for Different Cities

### Paris
```json
{
  "Location": "Paris",
  "CorrelationId": "aaaaaaaa-1111-2222-3333-bbbbbbbbbbbb"
}
```

### Tokyo
```json
{
  "Location": "Tokyo",
  "CorrelationId": "cccccccc-4444-5555-6666-dddddddddddd"
}
```

### New York
```json
{
  "Location": "New York",
  "CorrelationId": "eeeeeeee-7777-8888-9999-ffffffffffff"
}
```

## Complete Example Script

Here's a complete PowerShell script to test the function:

```powershell
# Login and set context
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Variables
$RESOURCE_GROUP = "rg-agent-test"
$STORAGE_ACCOUNT = "mkagentstorage"
$INPUT_QUEUE = "tool-input"
$OUTPUT_QUEUE = "tool-output"

# Get connection string
$CONNECTION_STRING = az storage account show-connection-string `
  --name $STORAGE_ACCOUNT `
  --resource-group $RESOURCE_GROUP `
  --query connectionString `
  --output tsv

# Send message
$MESSAGE = @"
{
  "Location": "Berlin",
  "CorrelationId": "12345678-1234-1234-1234-123456789abc"
}
"@

az storage message put `
  --queue-name $INPUT_QUEUE `
  --content $MESSAGE `
  --connection-string $CONNECTION_STRING

Write-Host "Message sent to input queue. Waiting 5 seconds..."
Start-Sleep -Seconds 5

# Read response
Write-Host "`nReading from output queue:"
az storage message peek `
  --queue-name $OUTPUT_QUEUE `
  --num-messages 5 `
  --connection-string $CONNECTION_STRING
```

## Monitoring

### View Logs in Application Insights

The function logs the following information:
- When a weather request is received (with location and correlation ID)
- The generated temperature for the location

### Query Logs

```kusto
traces
| where message contains "WeatherServiceQueue"
| project timestamp, message, severityLevel
| order by timestamp desc
```

## Configuration

### Environment Variables

The function uses the following app settings:

- `AzureWebJobsStorage`: Storage account connection string
- `QueueInputName`: Name of the input queue (default: `tool-input`)
- `QueueOutputName`: Name of the output queue (default: `tool-output`)
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Application Insights connection string for logging

### Retry Policy

The function is configured with a maximum of 2 dequeue attempts. After 2 failed attempts, the message moves to the poison queue (`tool-input-poison`).

## Temperature Range

The function generates random temperatures in the following range:
- **Minimum**: -15°C
- **Maximum**: 45°C
- **Unit**: Celsius

## Error Handling

If a message cannot be processed after the maximum retry attempts, it will be moved to the poison queue for manual inspection:
- Input poison queue: `tool-input-poison`

You can inspect poison messages with:

```bash
az storage message peek \
  --queue-name tool-input-poison \
  --num-messages 10 \
  --connection-string "$CONNECTION_STRING"
```

## Cleaning Up Test Messages

To clear messages from a queue:

```bash
az storage message clear \
  --queue-name $OUTPUT_QUEUE \
  --connection-string "$CONNECTION_STRING"
```
