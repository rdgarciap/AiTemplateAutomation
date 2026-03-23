  05 — AWS SSO Setup

**Tipo:** Referencia - ConfiguraciÓn Operativa  
**Depende de:** `07a_Database_Setup.md`, `01_Stack_Setup.md`

Este documento explica cÓmo configurar AWS SSO (Single Sign-On) para que cualquier usuario pueda autenticarse y acceder a AWS Secrets Manager, DynamoDB u otros servicios AWS desde el proyecto, independientemente de su perfil o cuenta.

---

   Alcance

1. ConfiguraciÓn inicial de AWS CLI y AWS SSO
2. GestiÓn de perfiles de AWS para mÚltiples cuentas/entornos
3. RenovaciÓn y manejo de tokens expirados
4. ConfiguraciÓn de variables de entorno para Visual Studio y otros IDEs
5. Troubleshooting de problemas comunes de autenticaciÓn

   Limites

1. No cubre la creaciÓn de cuentas AWS o configuraciÓn de IAM roles (responsabilidad del equipo de infraestructura)
2. No redefine el contrato de `appsettings.json` (ver `01_Stack_Setup.md`)
3. No explica la implementaciÓn interna de `AwsSecretsManagerDriver` (ver `02a_Core_Implementation.md`)

---

   �1 — Prerrequisitos

    1.1 InstalaciÓn de AWS CLI v2

Descarga e instala AWS CLI desde:
- **Windows:** https://awscli.amazonaws.com/AWSCLIV2.msi
- **macOS:** `brew install awscli`
- **Linux:** https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Verifica la instalaciÓn:
```powershell
aws --version
```

DeberÍas ver algo como: `aws-cli/2.x.x Python/3.x.x ...`

    1.2 Requisitos del Proyecto

El proyecto ya incluye las dependencias necesarias para AWS SSO:

```xml
<PackageReference Include="AWSSDK.Core" Version="4.0.3.19" />
<PackageReference Include="AWSSDK.SSO" Version="4.0.2.17" />
<PackageReference Include="AWSSDK.SSOOIDC" Version="4.0.3.7" />
<PackageReference Include="AWSSDK.SecurityToken" Version="4.0.5.13" />
<PackageReference Include="AWSSDK.SecretsManager" Version="4.0.2.17" />
```

Estas dependencias son **obligatorias** incluso si consumes AWS indirectamente vÍa `Gbm.Automation.Core`.

---

   �2 — ConfiguraciÓn Inicial de AWS SSO

    2.1 Obtener informaciÓn de tu organizaciÓn

Necesitas estos datos de tu equipo de infraestructura o DevOps:

1. **SSO Start URL** (ejemplo: `https://d-9067xxxxxx.awsapps.com/start`)
2. **SSO Region** (ejemplo: `us-east-1`)
3. **Account ID** (ejemplo: `055587831261`)
4. **Role Name** (ejemplo: `AWSReservedSSO_CBGBMBoaDevDev_xxxxxxxxxxxx`)

    2.2 Configurar tu primer perfil

Ejecuta en PowerShell o terminal:

```powershell
aws configure sso
```

Responde las preguntas:

```
SSO session name (Recommended): mi-sesion-sso
SSO start URL [None]: https://d-9067xxxxxx.awsapps.com/start
SSO region [None]: us-east-1
SSO registration scopes [sso:account:access]: [presiona Enter]
```

El navegador se abrirÁ para autenticarte. DespuÉs de autenticarte, regresa a la terminal:

```
There are N AWS accounts available to you.
> [Selecciona tu cuenta con las flechas y Enter]

There are N roles available to you.
> [Selecciona tu rol]

CLI default client Region [None]: us-east-1
CLI default output format [None]: json
CLI profile name [default-055587831261-role]: BOA-DEV
```

**?? Tip:** Usa nombres de perfil descriptivos como `BOA-DEV`, `BOA-QA`, `PROYECTO-PROD`, etc.

    2.3 Verificar la configuraciÓn

Tus perfiles se guardan en:
- **Windows:** `%USERPROFILE%\.aws\config`
- **macOS/Linux:** `~/.aws/config`

Ejemplo del archivo `config`:

```ini
[profile BOA-DEV]
sso_session = mi-sesion-sso
sso_account_id = 055587831261
sso_role_name = AWSReservedSSO_CBGBMBoaDevDev_xxxxxxxxxxxx
region = us-east-1
output = json

[sso-session mi-sesion-sso]
sso_start_url = https://d-9067xxxxxx.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access
```

---

   �3 — Uso Diario: Login y RenovaciÓn

    3.1 Iniciar sesiÓn (Login)

Cada token de AWS SSO expira despuÉs de **8 horas** (por defecto). Cuando expire, ejecuta:

```powershell
aws sso login --profile BOA-DEV
```

El navegador se abrirÁ para renovar tu token. DespuÉs de confirmar, la sesiÓn estarÁ activa.

    3.2 Verificar que la sesiÓn estÁ activa

```powershell
aws sts get-caller-identity --profile BOA-DEV
```

DeberÍas ver tu `UserId`, `Account` y `Arn`:

```json
{
    "UserId": "AROAQZ4KK7XO2SAJJWDRJ:tu-email@dominio.com",
    "Account": "055587831261",
    "Arn": "arn:aws:sts::055587831261:assumed-role/TuRol/tu-email@dominio.com"
}
```

    3.3 Error comÚn: Token expirado

```
An error occurred (ExpiredToken) when calling the GetCallerIdentity operation:
The security token included in the request is expired
```

**SoluciÓn:** Ejecuta `aws sso login --profile TU-PERFIL` para renovar.

---

   �4 — ConfiguraciÓn para Visual Studio / IDEs

Visual Studio y otros IDEs **no heredan automÁticamente** las credenciales de AWS SSO. Necesitas configurar variables de entorno.

    4.1 OpciÓn A: Variables de entorno de usuario (Recomendado)

Configura el perfil por defecto a nivel de sistema:

```powershell
  PowerShell (ejecutar como usuario normal)
[System.Environment]::SetEnvironmentVariable("AWS_PROFILE", "BOA-DEV", "User")
[System.Environment]::SetEnvironmentVariable("AWS_REGION", "us-east-1", "User")
```

**?? IMPORTANTE:** DespuÉs de esto, **reinicia Visual Studio** para que tome las variables.

    4.2 OpciÓn B: launchSettings.json (Por proyecto)

Crea o edita `Properties/launchSettings.json` en tu proyecto de tests:

```json
{
  "profiles": {
    "<ProjectName>": {
      "commandName": "Project",
      "environmentVariables": {
        "AWS_PROFILE": "BOA-DEV",
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

**Ventaja:** No afecta otros proyectos.  
**Desventaja:** Debes configurarlo en cada proyecto.

    4.3 OpciÓn C: Variables de sesiÓn (Temporal)

Si solo necesitas configurarlo para una sesiÓn:

```powershell
$env:AWS_PROFILE = "BOA-DEV"
$env:AWS_REGION = "us-east-1"
```

Luego ejecuta Visual Studio desde esa terminal:

```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe" <ProjectName>.sln
```

    4.4 Verificar variables de entorno en Visual Studio

En el Output Window de Visual Studio durante el debug, deberÍas ver en los logs:

```
AWS_PROFILE: BOA-DEV
AWS_REGION: us-east-1
```

O ejecuta en la ventana de Immediate Window (`Ctrl+Alt+I`):

```csharp
System.Environment.GetEnvironmentVariable("AWS_PROFILE")
```

---

   �5 — M�ltiples Perfiles y Cuentas

    5.1 Agregar perfiles adicionales

Para trabajar con mÚltiples cuentas o entornos:

```powershell
aws configure sso --profile BOA-QA
aws configure sso --profile BOA-PROD
aws configure sso --profile OTRO-PROYECTO-DEV
```

    5.2 Cambiar entre perfiles

**En terminal:**
```powershell
$env:AWS_PROFILE = "BOA-QA"
aws sts get-caller-identity --profile BOA-QA
```

**En appsettings.json:**
```json
{
  "AWSSettings": {
    "Region": "us-east-1",
    "Secrets": {
      "SobConnectionString": "/gbm/boa/qa/sob-credentials"
    }
  }
}
```

**En launchSettings.json:**
```json
{
  "profiles": {
    "Development": {
      "environmentVariables": {
        "AWS_PROFILE": "BOA-DEV"
      }
    },
    "QA": {
      "environmentVariables": {
        "AWS_PROFILE": "BOA-QA"
      }
    }
  }
}
```

    5.3 Ver todos tus perfiles

```powershell
aws configure list-profiles
```

---

   �6 — Formato del Secreto en AWS Secrets Manager

    6.1 Estructura esperada por el proyecto

Los secretos de conexiÓn a base de datos deben tener este formato JSON:

```json
{
  "server": "172.20.2.116",
  "port": "1433",
  "user_id": "usrBOADev",
  "password": "P@ssw0rd!",
  "database": "db1sob"
}
```

**?? Importante:** Las claves deben estar en **snake_case** (`user_id`, no `UserId`). El cÓdigo incluye mapeo automÁtico vÍa `[JsonProperty]` en `DataConnectionSettings.cs`.

    6.2 Probar acceso al secreto

```powershell
aws secretsmanager get-secret-value `
  --secret-id "/gbm/boa/mamba/sob-credentials" `
  --profile BOA-DEV `
  --region us-east-1 `
  --query 'SecretString' `
  --output text
```

DeberÍas ver el JSON del secreto.

    6.3 Si el secreto no existe o no tienes permisos

```
An error occurred (ResourceNotFoundException): Secrets Manager can't find the specified secret.
```

**SoluciÓn:**
1. Verifica el nombre del secreto en `appsettings.json`
2. Confirma que tu rol IAM tiene permisos `secretsmanager:GetSecretValue`
3. Contacta al equipo de infraestructura para solicitar acceso

---

   �7 — ConfiguraciÓn en appsettings.json

    7.1 ConfiguraciÓn para usar AWS Secrets Manager

```json
{
  "AWSSettings": {
    "Region": "us-east-1",
    "Secrets": {
      "SobConnectionString": "/gbm/boa/mamba/sob-credentials"
    }
  },
  "DatabaseSettings": {
    "ConnectionString": "Server=REPLACE_ME;Database=REPLACE_ME;...",
    "TimeoutSeconds": 30,
    "UseTransactionByDefault": false,
    "Provider": "SqlServer"
  }
}
```

    7.2 LÓgica de fallback

El cÓdigo sigue esta jerarquÍa:

1. **Si `AWSSettings:Secrets:SobConnectionString` tiene valor:**
   - Intenta obtener el secreto de AWS
   - Si AWS falla (token expirado, sin permisos, etc.), hace fallback al paso 2
   
2. **Si `DatabaseSettings:ConnectionString` NO contiene `REPLACE_ME`:**
   - Usa la cadena de conexiÓn local
   
3. **Si ambos fallan:**
   - Retorna cadena vacÍa y los tests relacionados con BD no se ejecutan

    7.3 Desarrollo local sin AWS

Si quieres trabajar sin AWS temporalmente:

```json
{
  "AWSSettings": {
    "Secrets": {
      "SobConnectionString": ""
    }
  },
  "DatabaseSettings": {
    "ConnectionString": "Server=localhost;Database=TestDB;Integrated Security=true;TrustServerCertificate=True;"
  }
}
```

**?? Nunca comitees credenciales reales en `appsettings.json`.**

---

   �8 — Troubleshooting

    8.1 "ExpiredToken" en Visual Studio

**SÍntoma:** El debug falla con `Amazon.SecretsManager.AmazonSecretsManagerException` y en los logs aparece "ExpiredToken".

**Causa:** Tu token de AWS SSO expir� (dura 8 horas).

**SoluciÓn:**
```powershell
aws sso login --profile BOA-DEV
```

Luego reinicia el debug.

    8.2 Visual Studio no encuentra las credenciales

**SÍntoma:** Error "Warning: AWS credentials not found in environment."

**Causa:** Visual Studio no tiene configurada la variable `AWS_PROFILE`.

**SoluciÓn:**
1. Verifica que `launchSettings.json` existe y tiene `AWS_PROFILE`
2. O configura la variable de usuario:
   ```powershell
   [System.Environment]::SetEnvironmentVariable("AWS_PROFILE", "BOA-DEV", "User")
   ```
3. **Reinicia Visual Studio**

    8.3 "ResourceNotFoundException" al acceder al secreto

**Causa:** El secreto no existe o tu rol no tiene permisos.

**SoluciÓn:**
1. Verifica el nombre del secreto:
   ```powershell
   aws secretsmanager list-secrets --profile BOA-DEV --region us-east-1
   ```
2. Pide al equipo de infraestructura que agregue tu rol a la polÍtica del secreto

    8.4 "Unable to locate credentials"

**Causa:** AWS CLI no encuentra ningÚn perfil configurado.

**SoluciÓn:**
```powershell
aws configure sso --profile MI-PERFIL
```

    8.5 Error al deserializar el secreto

**SÍntoma:** "AWS secret for database connection could not be deserialized."

**Causa:** El formato del secreto no coincide con lo esperado.

**SoluciÓn:**
1. Verifica que el secreto sea un JSON vÁlido
2. Confirma que las claves estÁn en snake_case: `server`, `port`, `user_id`, `password`, `database`
3. Ejemplo correcto:
   ```json
   {
     "server": "172.20.2.116",
     "port": "1433",
     "user_id": "usuario",
     "password": "contraseña",
     "database": "nombreDB"
   }
   ```

    8.6 Logs de depuraciÓn

El cÓdigo incluye logs informativos en consola:

```
Warning: AWS credentials not found in environment. Skipping AWS Secrets Manager.
Warning: Could not retrieve AWS secret. Falling back to local connection string. Error: ...
Warning: Failed to retrieve AWS secret '/path/to/secret': ExpiredToken
```

Estos logs son **normales** en desarrollo local sin AWS configurado.

---

   �9 — IntegraciÓn con CI/CD (AWS CodeBuild)

    9.1 Variables de entorno en buildspec.yml

```yaml
env:
  secrets-manager:
    DB_CONN_STR: "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:test/db-connection-SUFFIX"

phases:
  pre_build:
    commands:
      - export DatabaseSettings__ConnectionString="$DB_CONN_STR"
      - export AWS_REGION="us-east-1"
```

En CI/CD, CodeBuild ya tiene credenciales de la instancia (IAM Role), **no necesitas** `aws sso login`.

    9.2 Usar secretos directamente en CI/CD

El cÓdigo soporta inyectar la cadena de conexiÓn completa sin pasar por Secrets Manager:

```yaml
env:
  secrets-manager:
    DB_CONN_STR: "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:db-SUFFIX"

phases:
  pre_build:
    commands:
      - export DatabaseSettings__ConnectionString="$DB_CONN_STR"
        El driver detecta que ya hay una cadena y no intenta AWS Secrets Manager
```

---

   �10 — Checklist de ConfiguraciÓn

Usa esta lista para verificar que todo estÁ configurado:

**ConfiguraciÓn inicial (una sola vez):**
- [ ] AWS CLI v2 instalado (`aws --version`)
- [ ] Perfil SSO configurado (`aws configure sso --profile MI-PERFIL`)
- [ ] Variable de usuario `AWS_PROFILE` configurada o `launchSettings.json` creado
- [ ] Acceso al secreto verificado (`aws secretsmanager get-secret-value...`)

**Antes de cada sesiÓn de desarrollo:**
- [ ] Token renovado (`aws sso login --profile MI-PERFIL`)
- [ ] SesiÓn verificada (`aws sts get-caller-identity --profile MI-PERFIL`)
- [ ] Visual Studio reiniciado (si cambiaste variables de entorno)

**En cada proyecto nuevo:**
- [ ] `appsettings.json` configurado con `AWSSettings:Region` y `Secrets:SobConnectionString`
- [ ] `launchSettings.json` creado con `AWS_PROFILE` (si no usas variable de usuario)
- [ ] Dependencias AWS incluidas en `.csproj` (ver �1.2)

---

   �11 — Resumen

    Comandos mÁs usados:

```powershell
  Configurar un nuevo perfil
aws configure sso --profile MI-PERFIL

  Ver perfiles disponibles
aws configure list-profiles

  Hacer login
aws sso login --profile MI-PERFIL

  Verificar sesiÓn activa
aws sts get-caller-identity --profile MI-PERFIL

  Probar acceso a un secreto
aws secretsmanager get-secret-value --secret-id "/path/to/secret" --profile MI-PERFIL --region us-east-1

  Configurar variable de entorno permanente
[System.Environment]::SetEnvironmentVariable("AWS_PROFILE", "MI-PERFIL", "User")

  Configurar variable de sesiÓn (temporal)
$env:AWS_PROFILE = "MI-PERFIL"
```

    Archivos importantes:

- `~/.aws/config` - ConfiguraciÓn de perfiles
- `Properties/launchSettings.json` - Variables de entorno para Visual Studio
- `appsettings.json` - ConfiguraciÓn de AWS region y secretos
- `DataConnectionSettings.cs` - Mapeo del formato del secreto

    Soporte:

Para problemas de permisos, roles o secretos, contacta al equipo de DevOps/Infraestructura de tu organizaciÓn.

---

**Última actualizaciÓn:** Enero 2025  
**VersiÓn del documento:** 1.0  
**Compatibilidad:** AWS CLI v2, .NET 8, AWS SDK v4



