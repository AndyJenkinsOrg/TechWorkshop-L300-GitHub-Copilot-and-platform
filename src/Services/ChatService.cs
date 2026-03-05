using Azure;
using Azure.AI.OpenAI;
using Azure.Identity;
using OpenAI.Chat;

namespace ZavaStorefront.Services;

public class ChatService
{
    private readonly ILogger<ChatService> _logger;
    private readonly ChatClient _chatClient;

    public ChatService(ILogger<ChatService> logger, IConfiguration configuration)
    {
        _logger = logger;

        var endpoint = configuration["AIServices:Endpoint"]
            ?? throw new InvalidOperationException("Missing required configuration 'AIServices:Endpoint'.");
        var deploymentName = configuration["AIServices:DeploymentName"] ?? "Phi-4";

        var azureClient = new AzureOpenAIClient(
            new Uri(endpoint),
            new DefaultAzureCredential());

        _chatClient = azureClient.GetChatClient(deploymentName);
    }

    public async Task<string> SendMessageAsync(string userMessage)
    {
        _logger.LogInformation("Sending chat message to AI endpoint");

        try
        {
            var messages = new List<ChatMessage>
            {
                new SystemChatMessage("You are a helpful shopping assistant for Zava Storefront, an online store. Be concise and friendly."),
                new UserChatMessage(userMessage)
            };

            ChatCompletion completion = await _chatClient.CompleteChatAsync(messages);

            var response = completion.Content[0].Text;
            _logger.LogInformation("Received AI response ({Length} chars)", response.Length);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error communicating with AI endpoint");
            return $"Error: {ex.GetType().Name}: {ex.Message}";
        }
    }
}
