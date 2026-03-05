using ZavaStorefront.Services;

var builder = WebApplication.CreateBuilder(args);

// Add Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Add services to the container.
builder.Services.AddControllersWithViews();

// Configure session state with Redis Cache in production, in-memory in development
if (builder.Environment.IsProduction())
{
    var redisHost = builder.Configuration["RedisCache:Host"] ?? "localhost";
    var redisPort = builder.Configuration["RedisCache:Port"] ?? "6380";
    var useSsl = builder.Configuration["RedisCache:Ssl"] == "true";
    
    var connectionString = $"{redisHost}:{redisPort},ssl={useSsl},abortConnect=false";
    
    builder.Services.AddStackExchangeRedisCache(options =>
    {
        options.Configuration = connectionString;
    });
}
else
{
    // Use in-memory cache for development
    builder.Services.AddDistributedMemoryCache();
}

builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    options.Cookie.SecurePolicy = builder.Environment.IsProduction() 
        ? Microsoft.AspNetCore.Http.CookieSecurePolicy.Always 
        : Microsoft.AspNetCore.Http.CookieSecurePolicy.SameAsRequest;
});

// Register application services
builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<ProductService>();
builder.Services.AddScoped<CartService>();

// Add health checks
builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseSession();

app.UseAuthorization();

// Health check endpoint for container orchestration
app.MapHealthChecks("/health");

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
