# 06 — AWS Integration Template

**Tipo:** Normativo / Template de Implementacion
**Depende de:** `05_AWS_SSO_Setup.md`, `01_Stack_Setup.md`, `02_Architecture_Layout.md`

Este documento define el template estandar para integracion con servicios AWS usando Gbm.Automation.Core. Los contratos de codigo viven en los templates bajo `templates/bootstrap/`; este documento los organiza, describe sus responsabilidades y define los patrones de uso.

> **Requiere:** `-UsePrivatePackages` en `bootstrap-template.ps1` para generar los componentes AWS avanzados (AwsClientFactory, SecretsManagerWrapper, AwsConnectionTest).

---

## Alcance

1. Arquitectura de componentes AWS en el template
2. Patron de validacion de sesion AWS
3. Componentes wrapper para AWS Secrets Manager
4. Patrones de uso y mejores practicas
5. Manejo de errores y fallbacks

## Principios de Diseno

1. **Fail-Fast con Informacion Clara:** Validar la sesion AWS antes de intentar operaciones.
2. **Graceful Degradation:** Caer a connection strings locales si AWS no esta disponible.
3. **Single Responsibility:** Un wrapper por servicio AWS.
4. **Factory Pattern:** Centralizar la creacion de clientes AWS en AwsClientFactory.
5. **Logging Exhaustivo:** Cada paso debe ser auditable via Console.WriteLine.

---

## Arquitectura de Componentes

### Jerarquia

```
TestLifecycleHooks (BeforeScenario)
    |
    +-> AwsSessionValidator          (validacion temprana, una vez por test run)
    |       |-> AmazonSecurityTokenServiceClient (STS GetCallerIdentity)
    |       |-> AwsCredentialsProvider           (resolucion de credenciales SSO)
    |
    +-> AwsSecretsManagerDriver      (resolucion de connection string)
            |-> AwsClientFactory     (factory centralizado, requiere -UsePrivatePackages)
                    |-> SecretsManagerWrapper
                            |-> Gbm.Automation.Core.Aws.SecretsManagerClient
```

### Flujo de Ejecucion por Escenario

```
BeforeScenario
  1. AwsSecretsManagerDriver.ResolveDatabaseConnectionStringAsync()
       |-> Si DatabaseConnectionSecretName tiene valor:
       |       |-> AwsCredentialsProvider.GetCredentials()
       |       |-> SecretsManagerClient.GetSecretValueAsync(secretName)
       |       |-> Deserializar a DataConnectionSettings
       |       |-> Construir connection string SQL Server
       |-> Si falla o secretName esta vacio:
               |-> Usar DatabaseSettings:ConnectionString de appsettings.json
```

---

## Mapa de Templates

| Componente | Template | Depende de |
|---|---|---|
| AwsCredentialsProvider | templates/bootstrap/Drivers/AwsCredentialsProvider.cs.template | Siempre generado |
| AwsSessionValidator | templates/bootstrap/Drivers/AwsSessionValidator.cs.template | Siempre generado |
| AwsSecretsManagerDriver | templates/bootstrap/Drivers/AwsSecretsManagerDriver.cs.template | Siempre generado |
| DataConnectionSettings | templates/bootstrap/Drivers/DataConnectionSettings.cs.template | Siempre generado |
| AwsClientFactory | templates/bootstrap/Drivers/Aws/AwsClientFactory.cs.template | -UsePrivatePackages |
| SecretsManagerWrapper | templates/bootstrap/Drivers/Aws/SecretsManagerWrapper.cs.template | -UsePrivatePackages |
| AwsConnectionTest | templates/bootstrap/Tests/AwsConnectionTest.cs.template | -UsePrivatePackages |
| launchSettings.json | templates/bootstrap/Properties/launchSettings.json.template | Siempre generado |

---

## 1 — Componente: AwsCredentialsProvider

**Template:** templates/bootstrap/Drivers/AwsCredentialsProvider.cs.template

### Responsabilidad

Resolver credenciales AWS con soporte SSO. Resuelve el problema de que el AWS SDK para .NET no refresca tokens SSO automaticamente.

### Contrato Publico

| Metodo | Descripcion |
|---|---|
| GetCredentials() | Retorna AWSCredentials. Usa cache de 1 hora. Intenta AWS_PROFILE -> CredentialProfileStoreChain -> FallbackCredentialsFactory. |
| ClearCache() | Limpia el cache de credenciales, forzando resolucion en el proximo llamado. |
| ValidateCredentialsAsync() | Llama STS GetCallerIdentity para confirmar que las credenciales actuales son validas. |

### Reglas

1. El cache expira en 1 hora (los tokens SSO duran 8 horas por defecto).
2. Los fallos de perfil son no fatales; se cae al FallbackCredentialsFactory.
3. ValidateCredentialsAsync retorna false en caso de error, no lanza excepcion.

---

## 2 — Componente: AwsSessionValidator

**Template:** templates/bootstrap/Drivers/AwsSessionValidator.cs.template

### Responsabilidad

Validar tempranamente que existe una sesion AWS activa. Cachea el resultado para que la validacion ocurra una sola vez por test run.

### Contrato Publico

| Metodo | Descripcion |
|---|---|
| ValidateSessionAsync() | Valida sesion via STS. Retorna true si valida. Cachea resultado. |
| ResetValidation() | Resetea el cache (util en AwsConnectionTest). |
| IsSessionValidated() | Consulta el estado actual sin revalidar. |

### Manejo de Errores

| Codigo de error | Comportamiento |
|---|---|
| ExpiredToken | Imprime instrucciones para aws sso login. Retorna false. |
| InvalidClientTokenId | Imprime instrucciones para verificar AWS_PROFILE. Retorna false. |
| AmazonClientException | Imprime workaround con aws configure export-credentials. Retorna false. |
| Cualquier otro | Imprime pasos generales de diagnostico. Retorna false. |

### Uso Opcional en BeforeTestRun

```csharp
[BeforeTestRun]
public static async Task BeforeTestRunAsync()
{
    var isValid = await AwsSessionValidator.ValidateSessionAsync();
    if (!isValid)
        Console.WriteLine("WARNING: AWS session is not valid. Tests requiring AWS may fail.");
}
```

---

## 3 — Componente: AwsClientFactory

**Template:** templates/bootstrap/Drivers/Aws/AwsClientFactory.cs.template
**Requiere:** -UsePrivatePackages

### Responsabilidad

Factory estatica que centraliza la creacion de clientes AWS. Garantiza que AWS_REGION, AWS_DEFAULT_REGION y AWS_SDK_LOAD_CONFIG esten configurados antes de crear cualquier cliente.

### Contrato Publico

| Metodo | Descripcion |
|---|---|
| Initialize(region) | Configura la region por defecto y variables de entorno AWS. Idempotente. |
| CreateSecretsManagerClient() | Crea ISecretManagerClient de Gbm.Automation.Core. |
| CreateSecretsManagerWrapper(region?) | Crea SecretsManagerWrapper con region configurable. |
| GetDefaultRegion() | Retorna la region configurada. |

---

## 4 — Componente: SecretsManagerWrapper

**Template:** templates/bootstrap/Drivers/Aws/SecretsManagerWrapper.cs.template
**Requiere:** -UsePrivatePackages

### Responsabilidad

Wrapper sobre Gbm.Automation.Core.Aws.SecretsManagerClient con deserializacion tipada y manejo de errores especifico.

### Contrato Publico

| Metodo | Descripcion |
|---|---|
| GetSecretStringAsync(secretName) | Retorna el secreto como string?. |
| GetSecretAsAsync<T>(secretName) | Deserializa el secreto JSON a tipo T. |
| GetDatabaseConnectionStringAsync(secretName) | Obtiene un secreto de BD y lo convierte en connection string SQL Server. |

### Modelo de Secreto de Base de Datos

Forma esperada del JSON en AWS Secrets Manager:

```json
{
  "server": "sqlserver.host",
  "port": "1433",
  "user_id": "usuario",
  "password": "password",
  "database": "NombreDB"
}
```

ToConnectionString() produce: `Server=host,puerto;Database=NombreDB;User Id=usuario;Password=password;TrustServerCertificate=True;Encrypt=True;`

El campo port es opcional; si esta vacio, se omite la coma en la cadena.

### Manejo de Errores

| Error | Comportamiento |
|---|---|
| ExpiredToken | Lanza InvalidOperationException con instruccion de aws sso login |
| ResourceNotFoundException | Lanza InvalidOperationException indicando que el secreto no existe |
| Error generico | Lanza InvalidOperationException wrapeando la excepcion original |

---

## 5 — Componente: AwsConnectionTest

**Template:** templates/bootstrap/Tests/AwsConnectionTest.cs.template
**Requiere:** -UsePrivatePackages

Test fixture con 5 tests para validar la integracion AWS:

| Test | Ejecucion |
|---|---|
| TestAwsSessionValidation | Automatica |
| TestAwsSecretsManagerDriver_ResolveDatabaseConnectionString | Automatica |
| TestSecretsManagerWrapper_GetSecretString | [Explicit] — solo manual |
| TestSecretsManagerWrapper_GetDatabaseSecret | [Explicit] — solo manual |
| TestSecretsManagerWrapper_GetConnectionString | [Explicit] — solo manual |

Los tests [Explicit] usan el secreto /gbm/boa/project/sqlserver-credentials. Actualizar el path al secreto real del proyecto antes de ejecutarlos.

---

## 6 — Patrones de Uso

### Patron 1: Obtener Secreto Simple

```csharp
using var wrapper = AwsClientFactory.CreateSecretsManagerWrapper();
var apiKey = await wrapper.GetSecretStringAsync("/myapp/api-key");
```

### Patron 2: Obtener Secreto Tipado

```csharp
public class ApiCredentials
{
    [JsonProperty("api_key")] public string ApiKey { get; set; } = string.Empty;
    [JsonProperty("api_secret")] public string ApiSecret { get; set; } = string.Empty;
}

using var wrapper = AwsClientFactory.CreateSecretsManagerWrapper();
var creds = await wrapper.GetSecretAsAsync<ApiCredentials>("/myapp/credentials");
```

### Patron 3: Obtener Connection String de BD

```csharp
using var wrapper = AwsClientFactory.CreateSecretsManagerWrapper();
var connString = await wrapper.GetDatabaseConnectionStringAsync("/myapp/db-credentials");
```

### Patron 4: Validacion Previa en un Step

```csharp
[Given(@"AWS session is valid")]
public async Task GivenAwsSessionIsValid()
{
    var isValid = await AwsSessionValidator.ValidateSessionAsync();
    Assert.That(isValid, Is.True, "AWS session must be valid for this scenario");
}
```

---

## 7 — Generacion con Bootstrap Script

```powershell
# Con paquetes privados (AwsClientFactory, SecretsManagerWrapper, AwsConnectionTest)
.\bootstrap-template.ps1 -UsePrivatePackages

# Con paquetes privados y soporte de base de datos completo
.\bootstrap-template.ps1 -UsePrivatePackages -IncludeDatabase

# Forzar sobreescritura si ya existe
.\bootstrap-template.ps1 -UsePrivatePackages -IncludeDatabase -Force
```

Los componentes AwsCredentialsProvider, AwsSessionValidator, AwsSecretsManagerDriver y launchSettings.json se generan siempre, independientemente de -UsePrivatePackages.

---

## 8 — Configuracion Requerida

### appsettings.json

```json
{
  "AWSSettings": {
    "Region": "us-east-1",
    "Secrets": {
      "SobConnectionString": "/gbm/boa/project/sqlserver-credentials"
    }
  }
}
```

### Properties/launchSettings.json

Generado por el bootstrap con AWS_PROFILE=BOA-DEV. Actualizar el perfil segun el entorno del proyecto.

### Dependencias .csproj

```xml
<PackageReference Include="AWSSDK.Core" Version="4.0.3.19" />
<PackageReference Include="AWSSDK.SSO" Version="4.0.2.17" />
<PackageReference Include="AWSSDK.SSOOIDC" Version="4.0.3.7" />
<PackageReference Include="AWSSDK.SecurityToken" Version="4.0.5.13" />
<PackageReference Include="AWSSDK.SecretsManager" Version="4.0.2.17" />
<!-- Solo con -UsePrivatePackages: -->
<PackageReference Include="Gbm.Automation.Core" Version="1.7.7" />
```

---

## 9 — Checklist para Agregar un Nuevo Servicio AWS

- [ ] Crear wrapper en Drivers/Aws/ServicioWrapper.cs (implementar IDisposable)
- [ ] Agregar metodo factory en AwsClientFactory
- [ ] Agregar modelo de datos si aplica (con atributos JsonProperty)
- [ ] Implementar manejo de errores especifico (patron when (ex.ErrorCode == ...))
- [ ] Crear template en templates/bootstrap/Drivers/Aws/ServicioWrapper.cs.template
- [ ] Agregar el Write-FileSafely correspondiente en bootstrap-template.ps1 bajo el bloque -UsePrivatePackages
- [ ] Crear test en Tests/AwsServicioTest.cs con tests [Explicit] para operaciones con costo
- [ ] Actualizar este documento con la descripcion del nuevo componente

---

## 10 — Anti-Patrones a Evitar

**NO** crear clientes AWS directamente en steps o skills:

```csharp
// MAL — sin configuracion de region ni manejo de errores
var client = new AmazonSecretsManagerClient();
```

**SI** usar el factory:

```csharp
// BIEN — toda la configuracion esta centralizada
using var wrapper = AwsClientFactory.CreateSecretsManagerWrapper(_config.AwsRegion);
```

**NO** cachear SecretsManagerWrapper como campo de clase — es IDisposable y debe usarse en un bloque using.

**NO** usar AwsSessionValidator en cada step — el resultado se cachea por test run.



