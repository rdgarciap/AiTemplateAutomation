  07a — Database Setup

**Tipo:** Referencia  
**Depende de:** `07_Database_Skill.md`, `05_AWS_SSO_Setup.md` (si usas AWS Secrets Manager)

Este archivo concentra el setup operativo del dominio de base de datos: feed privado, version del paquete, cadena de conexion, secretos y proveedor de base de datos.

   Alcance

1. Explica como restaurar dependencias privadas para escenarios con DB.
2. Define como inyectar y proteger la cadena de conexion.
3. Describe como cambiar el proveedor sin redefinir el contrato base.
4. Referencia la configuraciÓn de AWS SSO para acceso a secretos (ver `05_AWS_SSO_Setup.md`).

   Limites

1. No redefine `DatabaseSettings`; ese contrato vive en [prompts/01_Stack_Setup.md](prompts/01_Stack_Setup.md).
2. No redefine lifecycle ni DI; esas reglas viven en [prompts/02_Architecture_Layout.md](prompts/02_Architecture_Layout.md).
3. No contiene implementacion de steps ni skills; eso vive en [prompts/07e_Database_Implementation.md](prompts/07e_Database_Implementation.md).
4. No explica cÓmo configurar AWS CLI/SSO; eso vive en [prompts/05_AWS_SSO_Setup.md](prompts/05_AWS_SSO_Setup.md).

---

   �1 — AutenticaciÓn al feed privado (VSTS_GITHUB_ACCESS_KEY)

`Gbm.Automation.Core` se distribuye desde el feed privado de GitHub Packages.
`dotnet restore` necesita encontrar `VSTS_GITHUB_ACCESS_KEY` como variable de entorno
en la sesiÓn actual para autenticarse.

> **Problema conocido — VS Code terminal:**
> VS Code abre terminales como procesos hijo del editor. En Windows, estos procesos
> **no heredan** variables configuradas en el Ámbito de *Usuario* del sistema.
> El token puede existir en tu sistema y aun asÍ `dotnet restore` fallarÁ con `401 Unauthorized`.

    OpciÓn — InyecciÓn manual en la terminal

Si prefieres ejecutar los pasos por separado:

```powershell
  1. Leer el token desde el Ámbito de Usuario e inyectarlo en la sesiÓn actual
$env:VSTS_GITHUB_ACCESS_KEY = [System.Environment]::GetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "User")

  2. Verificar que se inyect� (no debe estar vacÍo)
echo $env:VSTS_GITHUB_ACCESS_KEY

  3. Restaurar paquetes
cd "src/$ProjectName"
dotnet restore
```

    Si el token no estÁ configurado en el sistema

```powershell
  Configurar el token a nivel de Usuario (solo necesario una vez por mÁquina)
[System.Environment]::SetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "ghp_TU_TOKEN_AQUI", "User")

  Luego cierra y reabre la terminal, o inyÉctalo directamente:
$env:VSTS_GITHUB_ACCESS_KEY = [System.Environment]::GetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "User")
```

> El token debe ser un GitHub Personal Access Token con scope `read:packages`
> para el repositorio `gbmcode/wall-e`.

    Dependencias AWS incluidas en el stack base

El template debe incluir desde el arranque estos paquetes para no romper autenticacion AWS en escenarios locales o CI con SSO, credenciales temporales o STS:

```xml
<PackageReference Include="AWSSDK.Core" Version="4.0.3.19" />
<PackageReference Include="AWSSDK.SSO" Version="4.0.2.17" />
<PackageReference Include="AWSSDK.SSOOIDC" Version="4.0.3.7" />
<PackageReference Include="AWSSDK.SecurityToken" Version="4.0.5.13" />
```

Estas dependencias deben existir incluso si el acceso a AWS se hace indirectamente via `Gbm.Automation.Core`, porque resuelven flujos de autenticacion necesarios para Secrets Manager, DynamoDB y otros clientes del SDK.

---

   �2 — Verificar y actualizar la versiÓn del paquete

    2.1 Consultar la versiÓn publicada

En el navegador, con sesion GitHub activa:
```
https://github.com/gbmcode/wall-e/packages
```
Busca `Gbm.Automation.Core` y anota la versiÓn mÁs reciente.

    2.2 Actualizar el .csproj

Archivo: `src/<ProjectName>/<ProjectName>.csproj`

Ejemplo con nombre por defecto: [src/DemoFinancialServicesQA/DemoFinancialServicesQA.csproj](src/DemoFinancialServicesQA/DemoFinancialServicesQA.csproj).

```xml
<PackageReference Include="Gbm.Automation.Core" Version="1.7.7" />
```

Reemplaza `1.7.7` por la versiÓn real que encontraste en el paso anterior.

---

   �3 — Configurar la cadena de conexiÓn

El template incluye una cadena dummy en `src/<ProjectName>/appsettings.json`.

Ejemplo con nombre por defecto: [src/DemoFinancialServicesQA/appsettings.json](src/DemoFinancialServicesQA/appsettings.json).

```json

```json
"DatabaseSettings": {
  "ConnectionString": "Server=REPLACE_ME;Database=REPLACE_ME;User Id=REPLACE_ME;Password=REPLACE_ME;TrustServerCertificate=True;",
  "TimeoutSeconds": 30,
  "UseTransactionByDefault": false,
  "Provider": "SqlServer"
}
```

Debes reemplazarla antes de ejecutar cualquier escenario con BD.

    OpciÓn A — Local: editar appsettings.json

> ?? **Nunca commitees credenciales reales.** Agrega `appsettings.json` a `.gitignore`
> si escribirÁs la cadena real en ese archivo.

```json
"DatabaseSettings": {
  "ConnectionString": "Server=tu-servidor.database.windows.net;Database=TuDB;User Id=usuario;Password=pass123;TrustServerCertificate=True;",
  "TimeoutSeconds": 30,
  "UseTransactionByDefault": false,
  "Provider": "SqlServer"
}
```

    OpciÓn B — Variable de entorno (recomendado para CI/CD)

Usa el separador `__` (doble guiÓn bajo) para sobrescribir claves de `appsettings.json`:

```powershell
  Windows PowerShell
$env:DatabaseSettings__ConnectionString = "Server=...;Database=...;..."
```

```bash
  Linux / macOS (CodeBuild)
export DatabaseSettings__ConnectionString="Server=...;Database=...;..."
```

`ConfigurationDriver` lo carga automÁticamente gracias a `AddEnvironmentVariables()`.

    OpciÓn C — AWS Secrets Manager (producciÓn / CI / desarrollo local)`n`n> **?? Prerequisito:** Configura AWS SSO siguiendo [prompts/05_AWS_SSO_Setup.md](prompts/05_AWS_SSO_Setup.md) antes de usar esta opciÓn.

El template puede resolver la cadena de conexiÓn directamente desde AWS Secrets Manager si configuras este esquema en `appsettings.json`:

```json
"AWSSettings": {
  "Region": "us-east-1",
  "Secrets": {
    "SobConnectionString": "/gbm/boa/mamba/sob-credentials"
  }
}
```

El secreto debe contener un JSON con esta forma:

```json
{
  "Server": "sqlserver.host",
  "Port": "1433",
  "UserId": "usuario",
  "Password": "password",
  "Database": "TuDB"
}
```

El hook usa `Gbm.Automation.Core.Aws.SecretsManagerClient` para obtener el secreto y luego construye una cadena SQL Server con el formato `Server=host,port;Database=...;User Id=...;Password=...;TrustServerCertificate=True;`.

Si `AWSSettings:Secrets:SobConnectionString` tiene valor, el template intenta resolver primero el secreto. Si no existe o esta vacio, usa el valor directo de `DatabaseSettings.ConnectionString`.

```yaml
  En build/buildspec-build.yml
env:
  secrets-manager:
    DB_CONN_STR: "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:test/db-connection-SUFFIX"

phases:
  pre_build:
    commands:
      - export DatabaseSettings__ConnectionString="$DB_CONN_STR"
```

---

   �4 — Cambiar el proveedor de base de datos (opcional)

Por defecto el template usa **SQL Server**. Para cambiarlo, ajusta `DatabaseSettings.Provider` y manten la implementacion del lifecycle alineada con ese valor.
Referencia recomendada: [prompts/02a_Core_Implementation.md](prompts/02a_Core_Implementation.md) y [prompts/07e_Database_Implementation.md](prompts/07e_Database_Implementation.md).

```csharp
// -- SQL Server (default) ----------------------------------------------
var dbClient = new DbClientBuilder()
  .UseSqlServer(config.DatabaseConnectionString)
  .WithTimeout(config.DatabaseTimeoutSeconds)
    .Build();

// -- PostgreSQL --------------------------------------------------------
var dbClient = new DbClientBuilder()
  .UsePostgres(config.DatabaseConnectionString)
    .WithTimeout(30)
    .Build();

// -- MySQL -------------------------------------------------------------
var dbClient = new DbClientBuilder()
  .UseMySql(config.DatabaseConnectionString)
    .WithTimeout(30)
    .Build();

// -- SQLite (sin BD externa — ideal para tests unitarios) --------------
var dbClient = new DbClientBuilder()
    .UseSqlite("test_local.db")
    .WithTimeout(30)
    .Build();

// -- Con transacciones por defecto (BEGIN TRAN en cada escritura) ------
var dbClient = new DbClientBuilder()
  .UseSqlServer(config.DatabaseConnectionString)
    .WithTimeout(30)
    .WithTransactionByDefault()   // IsolationLevel.ReadCommitted
    .Build();



