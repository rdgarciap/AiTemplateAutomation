# 02a — Core Implementation

**Tipo:** Implementacion  
**Depende de:** `01_Stack_Setup.md`, `02_Architecture_Layout.md`

Este archivo muestra una implementacion sugerida del core sin redefinir el contrato.

## Archivos esperados

1. `Drivers/AiContext.cs`
2. `Drivers/ConfigurationDriver.cs`
3. `Hooks/TestLifecycleHooks.cs`

## `AiContext.cs`

```csharp
namespace {{PROJECT_NAME}}.Drivers;

public class AiContext
{
    public string? LastRawResponse { get; set; }
    public object? LastSkillResult { get; set; }
    public List<string> ValidationErrors { get; } = new();
    public Dictionary<string, object> SharedData { get; } = new();
}
```

## `ConfigurationDriver.cs`

```csharp
using Microsoft.Extensions.Configuration;

namespace {{PROJECT_NAME}}.Drivers;

public class ConfigurationDriver
{
    private readonly IConfiguration _config;

    public ConfigurationDriver()
    {
        _config = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
            .AddEnvironmentVariables()
            .Build();
    }

    public string AiMode => _config["AiSettings:Mode"] ?? "online";
    public double AiTemperature => double.Parse(_config["AiSettings:Temperature"] ?? "0.0");
    public int AiMaxTokens => int.Parse(_config["AiSettings:MaxTokens"] ?? "500");

    public string OpenAiApiKey => _config["AiSettings:OpenAI:ApiKey"] ?? string.Empty;
    public string OpenAiModelId => _config["AiSettings:OpenAI:ModelId"] ?? "gpt-4o";

    public string AzureEndpoint => _config["AiSettings:AzureOpenAI:Endpoint"] ?? string.Empty;
    public string AzureApiKey => _config["AiSettings:AzureOpenAI:ApiKey"] ?? string.Empty;
    public string AzureDeployment => _config["AiSettings:AzureOpenAI:DeploymentName"] ?? string.Empty;
    public string AzureModelId => _config["AiSettings:AzureOpenAI:ModelId"] ?? "gpt-4o";

    public string DatabaseConnectionString => _config["DatabaseSettings:ConnectionString"] ?? string.Empty;
    public int DatabaseTimeoutSeconds => int.Parse(_config["DatabaseSettings:TimeoutSeconds"] ?? "30");
    public bool DatabaseUseTransaction => bool.Parse(_config["DatabaseSettings:UseTransactionByDefault"] ?? "false");
    public string DatabaseProvider => _config["DatabaseSettings:Provider"] ?? "SqlServer";
}
```

## `TestLifecycleHooks.cs`

> **Variantes:** Existen dos versiones del hook según si el proyecto usa base de datos o no.
> - **Base (sin DB):** `templates/bootstrap/Hooks/TestLifecycleHooks.cs.template` — registra `AiContext`, `ConfigurationDriver`, `Kernel`, `BrowserSkill` y `ApiSkill`.
> - **Con DB:** `templates/bootstrap/Hooks/TestLifecycleHooks.database.cs.template` — agrega `AwsSecretsManagerDriver` y registra `DatabaseSkill` si la conexión resuelve correctamente (vía secreto AWS o connection string directo).
>
> El bootstrap script (`bootstrap-template.ps1`) selecciona la variante correcta con el parámetro `-IncludeDatabase`.

### Variante base (sin base de datos)

```csharp
using {{PROJECT_NAME}}.Drivers;
using {{PROJECT_NAME}}.Skills;
using Microsoft.SemanticKernel;
using Reqnroll;
using Reqnroll.BoDi;

namespace {{PROJECT_NAME}}.Hooks;

[Binding]
public class TestLifecycleHooks
{
    private readonly IObjectContainer _container;

    public TestLifecycleHooks(IObjectContainer container)
    {
        _container = container;
    }

    [BeforeScenario]
    public void SetupScenario()
    {
        var config = new ConfigurationDriver();
        var aiContext = new AiContext();

        _container.RegisterInstanceAs(config);
        _container.RegisterInstanceAs(aiContext);

        var builder = Kernel.CreateBuilder();
        if (config.AiMode.Equals("azure", StringComparison.OrdinalIgnoreCase))
        {
            builder.AddAzureOpenAIChatCompletion(
                deploymentName: config.AzureDeployment,
                endpoint: config.AzureEndpoint,
                apiKey: config.AzureApiKey,
                modelId: config.AzureModelId);
        }
        else
        {
            builder.AddOpenAIChatCompletion(
                modelId: config.OpenAiModelId,
                apiKey: config.OpenAiApiKey);
        }

        var kernel = builder.Build();
        _container.RegisterInstanceAs(kernel);

        var browserSkill = new BrowserSkill(aiContext);
        var apiSkill = new ApiSkill(aiContext);

        kernel.ImportPluginFromObject(browserSkill, "Browser");
        kernel.ImportPluginFromObject(apiSkill, "Api");

        _container.RegisterInstanceAs(browserSkill);
        _container.RegisterInstanceAs(apiSkill);
    }

    [AfterScenario]
    public void TeardownScenario()
    {
        // Release UI drivers, open connections, or other external resources here.
    }
}
```

### Variante con base de datos

Consultar el template `templates/bootstrap/Hooks/TestLifecycleHooks.database.cs.template`. Usa `AwsSecretsManagerDriver.ResolveDatabaseConnectionStringAsync()` para resolver la cadena de conexión (vía AWS Secrets Manager o connection string directo), y solo registra `DatabaseSkill` si la cadena resuelve a un valor no vacío.



