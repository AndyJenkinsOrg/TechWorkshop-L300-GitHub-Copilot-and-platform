# Multi-stage build for .NET 10 ASP.NET Core MVC application
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files
COPY ["src/ZavaStorefront.csproj", "src/"]
COPY ["src/", "src/"]

# Restore dependencies
RUN dotnet restore "src/ZavaStorefront.csproj"

# Build application
RUN dotnet build "src/ZavaStorefront.csproj" -c Release -o /app/build

# Publish
FROM build AS publish
RUN dotnet publish "src/ZavaStorefront.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy published application
COPY --from=publish /app/publish .

# Create non-root user for security
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run application
ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
