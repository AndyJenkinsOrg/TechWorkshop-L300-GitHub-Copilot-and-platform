# Copilot Instructions

## Build and Run

All commands run from the `src/` directory:

```bash
dotnet restore          # Restore dependencies
dotnet build            # Build the project
dotnet run              # Run locally (https://localhost:7060)
```

Docker build from repo root:

```bash
docker build -t zava-storefront .
docker run -p 8080:8080 zava-storefront
```

There is no test project in the repository.

## Architecture

**Zava Storefront** is an ASP.NET Core MVC e-commerce app targeting .NET 10. It has no database — product data is hardcoded in `ProductService` and cart state is stored in the HTTP session.

### Key layers

- **Models** (`src/Models/`): `Product`, `CartItem`, `ErrorViewModel` — plain POCOs with no validation attributes or persistence logic.
- **Services** (`src/Services/`): Business logic layer injected via DI.
  - `ProductService` (Singleton) — static in-memory product catalog. To add/change products, edit the `_products` list directly.
  - `CartService` (Scoped) — reads/writes cart as JSON in `ISession`. Depends on `IHttpContextAccessor` and `ProductService`.
- **Controllers** (`src/Controllers/`): Thin controllers that delegate to services. `HomeController` handles product listing and add-to-cart; `CartController` handles cart view, quantity updates, removal, and checkout.
- **Views** (`src/Views/`): Razor views using Bootstrap 5. Layout with cart icon badge is in `Shared/_Layout.cshtml`.

### Session and caching

Configured in `Program.cs`: development uses in-memory distributed cache; production uses Redis (configured via `RedisCache:Host`, `RedisCache:Port`, `RedisCache:Ssl` in app settings). Session timeout is 30 minutes.

### Infrastructure

- **Dockerfile**: Multi-stage build (SDK → publish → aspnet runtime), runs as non-root user on port 8080.
- **Azure deployment**: Bicep templates in `infra/` for Azure resource provisioning. `azure.yaml` is the Azure Developer CLI config.
- **Health checks**: Exposed at `/health`.
- **Telemetry**: Application Insights is configured via `Microsoft.ApplicationInsights.AspNetCore`.

## Conventions

- `Program.cs` uses top-level statements (minimal hosting model) — no `Startup.cs`.
- Services are registered as concrete types (not interfaces). `ProductService` is singleton; `CartService` is scoped.
- Controllers use structured logging with `ILogger<T>` and message templates (e.g., `"Adding product {ProductId} ({ProductName}) to cart"`).
- State-changing actions use `[HttpPost]` and redirect via POST-Redirect-GET pattern.
- All models use the `ZavaStorefront.Models` namespace; services use `ZavaStorefront.Services`.
