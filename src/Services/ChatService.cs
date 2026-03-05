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
        var deploymentName = configuration["AIServices:DeploymentName"] ?? "gpt-4o";
        var managedIdentityClientId = configuration["AZURE_CLIENT_ID"];

        // Use ManagedIdentityCredential with explicit client ID for user-assigned identity,
        // fall back to DefaultAzureCredential for local development
        Azure.Core.TokenCredential credential = !string.IsNullOrEmpty(managedIdentityClientId)
            ? new ManagedIdentityCredential(managedIdentityClientId)
            : new DefaultAzureCredential();

        _logger.LogInformation("ChatService configured: endpoint={Endpoint}, deployment={Deployment}, hasManagedIdentity={HasMI}",
            endpoint, deploymentName, !string.IsNullOrEmpty(managedIdentityClientId));

        var azureClient = new AzureOpenAIClient(
            new Uri(endpoint),
            credential);

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
