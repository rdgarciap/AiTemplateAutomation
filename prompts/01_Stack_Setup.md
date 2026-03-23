# 01 — Stack y Configuración Base

**Tipo:** Normativo  
**Rol:** Contrato tecnico base del proyecto

Este archivo define el stack soportado y la estructura minima de configuracion. Ningun documento de implementacion debe contradecir este contrato.

## Stack soportado

| Componente | Paquete | Version base | Observaciones |
|---|---|---|---|
| Runtime | .NET | `net8.0` | Version objetivo del template. |
| Orquestador IA | `Microsoft.SemanticKernel` | `1.30.0` | Base de plugins y prompt orchestration. |
| BDD | `Reqnroll` | `2.4.0` | Runner Gherkin. |
| BDD + NUnit | `Reqnroll.NUnit` | `2.4.0` | Integracion con NUnit. |
| Test engine | `NUnit` | `4.2.2` | Aserciones y estructura de pruebas. |
| Test discovery | `NUnit3TestAdapter` | `4.6.0` | Descubrimiento en IDE y CI. |
| Test SDK | `Microsoft.NET.Test.Sdk` | `17.12.0` | Soporte del runner. |
| Config JSON | `Microsoft.Extensions.Configuration.Json` | `10.0.1` | Requerido por dependencias del template. |
| Config Env | `Microsoft.Extensions.Configuration.EnvironmentVariables` | `9.0.0` | Sobrescritura por variables de entorno. |
| DI | `Microsoft.Extensions.DependencyInjection` | `8.0.1` | Puede usarse junto con BoDi si se necesita. |
| AWS Core | `AWSSDK.Core` | `4.0.3.19` | Base de autenticacion y credenciales del SDK de AWS. |
| AWS SSO | `AWSSDK.SSO` | `4.0.2.17` | Requerido para sesiones autenticadas con AWS IAM Identity Center. |
| AWS SSO OIDC | `AWSSDK.SSOOIDC` | `4.0.3.7` | Necesario para el flujo de login y refresh de AWS SSO. |
| AWS STS | `AWSSDK.SecurityToken` | `4.0.5.13` | Soporte para credenciales temporales y AssumeRole/STS. |
| AWS Secrets | `AWSSDK.SecretsManager` | `4.0.2.17` | Requerido para acceder a AWS Secrets Manager directamente o via `Gbm.Automation.Core`. |
| DB Core | `Gbm.Automation.Core` | `1.7.7` | Paquete privado opcional para DB y otras utilidades. |
| Mapeo SQL | `Dapper` | `2.1.66` | Necesario para flujos de base de datos. |
| JSON | `Newtonsoft.Json` | `13.0.4` | Serializacion del orquestador y resultados. |

## Contrato del `.csproj`

El proyecto generado debe cumplir, como minimo, con estas reglas:

1. `TargetFramework = net8.0`
2. `IsTestProject = true`
3. `Nullable = enable`
4. `ImplicitUsings = enable`
5. Los archivos de configuracion leidos en runtime deben copiarse al output.

Archivos que deben copiarse al directorio de salida:

- `appsettings.json`
- `reqnroll.json`
- `Prompts/*.txt`
- `Scripts/*.sql` si existen escenarios con BD

## Contrato Canónico de `appsettings.json`

```json
{
  "AiSettings": {
    "Mode": "online",
    "Temperature": 0.0,
    "MaxTokens": 500,
    "OpenAI": {
      "ApiKey": "YOUR_KEY",
      "ModelId": "gpt-4o"
    },
    "AzureOpenAI": {
      "Endpoint": "https://RESOURCE.openai.azure.com/",
      "ApiKey": "YOUR_KEY",
      "DeploymentName": "YOUR_DEPLOYMENT",
      "ModelId": "gpt-4o"
    }
  },
  "DatabaseSettings": {
    "ConnectionString": "Server=REPLACE_ME;Database=REPLACE_ME;User Id=REPLACE_ME;Password=REPLACE_ME;TrustServerCertificate=True;",
    "TimeoutSeconds": 30,
    "UseTransactionByDefault": false,
    "Provider": "SqlServer"
  }
}
```

### Reglas de Configuración

1. `AiSettings.Temperature` debe ser `0.0` por defecto.
2. `DatabaseSettings` debe existir aunque el proyecto no use BD todavia.
3. Los secretos del archivo son placeholders; en ejecucion real deben sobrescribirse con variables de entorno o secretos del pipeline.
4. El proveedor de DB debe poder cambiarse sin alterar el contrato del resto del proyecto.
5. El stack base debe incluir los paquetes `AWSSDK.Core`, `AWSSDK.SSO`, `AWSSDK.SSOOIDC` y `AWSSDK.SecurityToken` para evitar problemas de autenticacion cuando el proyecto consuma AWS Secrets Manager, DynamoDB u otros servicios via credenciales SSO o temporales.

## Contrato Canónico de `reqnroll.json`

```json
{
  "language": {
    "feature": "en-US"
  },
  "bindingCulture": {
    "name": "en-US"
  },
  "runtime": {
    "missingOrPendingStepsOutcome": "Error",
    "traceSuccessfulSteps": true
  }
}
```

## Política de Secretos

1. No versionar API keys ni cadenas reales de conexion.
2. Sobrescribir usando variables con doble guion bajo, por ejemplo: `AiSettings__OpenAI__ApiKey`.
3. Para BD usar `DatabaseSettings__ConnectionString`.
4. En CI/CD, NuGet debe leer `VSTS_GITHUB_ACCESS_KEY` directamente desde el entorno.

## Política de Actualización de .NET

Al migrar de version:

1. Actualiza `TargetFramework`.
2. Actualiza [build/buildspec-build.yml](build/buildspec-build.yml).
3. Verifica versiones reales de paquetes en nuget.org o en el feed privado.
4. Revalida compatibilidad de Semantic Kernel y Reqnroll antes de publicar el cambio.

## Relación con Otros Prompts

- [prompts/02_Architecture_Layout.md](prompts/02_Architecture_Layout.md) consume este contrato de configuracion.
- [prompts/04_Prompt_Engineering.md](prompts/04_Prompt_Engineering.md) consume `AiSettings`.
- [prompts/07a_Database_Setup.md](prompts/07a_Database_Setup.md) amplia la parte operativa de `DatabaseSettings` sin redefinir su forma base.


