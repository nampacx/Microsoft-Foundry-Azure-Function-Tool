using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace FunctionApp
{
    public class QueueTriggerFunction
    {
        private readonly ILogger<QueueTriggerFunction> _logger;

        public QueueTriggerFunction(ILogger<QueueTriggerFunction> logger)
        {
            _logger = logger;
        }

        [Function(nameof(QueueTriggerFunction))]
        public void Run([QueueTrigger("tool-input", Connection = "AzureWebJobsStorage")] string myQueueItem)
        {
            _logger.LogInformation("C# Queue trigger function processed: {queueItem}", myQueueItem);
        }
    }
}
