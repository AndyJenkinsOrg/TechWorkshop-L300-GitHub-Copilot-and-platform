using Azure;
using Azure.AI.ContentSafety;
using Azure.AI.OpenAI;
using Azure.Identity;
using OpenAI.Chat;

namespace ZavaStorefront.Services;

public class ChatService
{
    private readonly ILogger<ChatService> _logger;
    private readonly ChatClient _chatClient;
    private readonly ContentSafetyClient _contentSafetyClient;

    public ChatService(ILogger<ChatService> logger, IConfiguration configuration)
    {
        _logger = logger;

        var endpoint = configuration["AIServices:Endpoint"]
            ?? throw new InvalidOperationException("Missing required configuration 'AIServices:Endpoint'.");
        var deploymentName = configuration["AIServices:DeploymentName"] ?? "Phi-4";
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
        _contentSafetyClient = new ContentSafetyClient(new Uri(endpoint), credential);
    }

    public async Task<string> SendMessageAsync(string userMessage)
    {
        _logger.LogInformation("Sending chat message to AI endpoint");

        try
        {
            var (isSafe, reason) = await EvaluateContentSafetyAsync(userMessage);
            if (!isSafe)
            {
                _logger.LogWarning("Message blocked by content safety: {Reason}", reason);
                return "⚠️ Your message was flagged as potentially unsafe and cannot be processed. Please rephrase your message.";
            }

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
            return "Sorry, I'm unable to respond right now. Please try again later.";
        }
    }

    private async Task<(bool IsSafe, string? Reason)> EvaluateContentSafetyAsync(string text)
    {
        try
        {
            var options = new AnalyzeTextOptions(text);

            var response = await _contentSafetyClient.AnalyzeTextAsync(options);
            var result = response.Value;

            const int threshold = 2;

            if (result.CategoriesAnalysis != null)
            {
                foreach (var category in result.CategoriesAnalysis)
                {
                    if (category.Severity.HasValue && category.Severity.Value >= threshold)
                    {
                        _logger.LogInformation("Content safety flagged: {Category} severity={Severity}",
                            category.Category, category.Severity.Value);
                        return (false, $"{category.Category} (severity {category.Severity.Value})");
                    }
                }
            }

            _logger.LogInformation("Content safety check passed");
            return (true, null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Content safety check failed, allowing message through");
            return (true, null);
        }
    }
}
