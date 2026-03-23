# Quick Start Checklist - AWS SSO Setup

## Configuración Inicial (Una sola vez por máquina)

- [ ] **AWS CLI v2 instalado**
  ```powershell
  aws --version  # Debe mostrar 2.x.x
  ```

- [ ] **Configurar perfil AWS SSO**
  ```powershell
  aws configure sso --profile MI-PERFIL
  ```
  - SSO Start URL: `https://d-xxxxxxxxx.awsapps.com/start` (proporcionado por infraestructura)
  - SSO Region: `us-east-1` (o tu región)
  - Account ID: Tu ID de cuenta AWS
  - Role: Tu rol asignado
  - CLI profile name: Nombre descriptivo (ej: `BOA-DEV`, `PROYECTO-QA`)

- [ ] **Configurar variable de entorno permanente** (recomendado)
  ```powershell
  [System.Environment]::SetEnvironmentVariable("AWS_PROFILE", "MI-PERFIL", "User")
  [System.Environment]::SetEnvironmentVariable("AWS_REGION", "us-east-1", "User")
  ```

- [ ] **Reiniciar Visual Studio** (para que tome las variables)

## Antes de Cada Sesión de Desarrollo (Diario)

- [ ] **Hacer login en AWS SSO** (tokens expiran cada 8 horas)
  ```powershell
  aws sso login --profile MI-PERFIL
  ```

- [ ] **Verificar sesión activa**
  ```powershell
  aws sts get-caller-identity --profile MI-PERFIL
  ```
  Debe mostrar tu `UserId`, `Account` y `Arn`

- [ ] **Verificar acceso al secreto** (si usas AWS Secrets Manager)
  ```powershell
  aws secretsmanager get-secret-value `
    --secret-id "/ruta/al/secreto" `
    --profile MI-PERFIL `
    --region us-east-1 `
    --query 'SecretString' `
    --output text
  ```

## Configuración del Proyecto

- [ ] **Verificar `appsettings.json`**
  ```json
  {
    "AWSSettings": {
      "Region": "us-east-1",
      "Secrets": {
        "SobConnectionString": "/ruta/al/secreto"
      }
    }
  }
  ```

- [ ] **Verificar `launchSettings.json`** existe con:
  ```json
  {
    "profiles": {
      "<ProjectName>": {
        "environmentVariables": {
          "AWS_PROFILE": "MI-PERFIL",
          "AWS_REGION": "us-east-1"
        }
      }
    }
  }
  ```

- [ ] **Dependencias AWS en `.csproj`**
  ```xml
  <PackageReference Include="AWSSDK.Core" Version="4.0.3.19" />
  <PackageReference Include="AWSSDK.SSO" Version="4.0.2.17" />
  <PackageReference Include="AWSSDK.SSOOIDC" Version="4.0.3.7" />
  <PackageReference Include="AWSSDK.SecurityToken" Version="4.0.5.13" />
  <PackageReference Include="AWSSDK.SecretsManager" Version="4.0.2.17" />
  ```

## Troubleshooting Rápido

### ? Error: "ExpiredToken"
```powershell
aws sso login --profile MI-PERFIL
```
**IMPORTANTE:** Después de renovar el token, **reinicia Visual Studio**.
### ❌ Error: "ExpiredToken" incluso después de hacer login (y `AWS_ACCESS_KEY_ID: SET` en los logs)

Hay credenciales estáticas expiradas guardadas como variables de entorno de Windows. Tienen prioridad sobre el perfil SSO.

**Diagnóstico:**
```powershell
[System.Environment]::GetEnvironmentVariable("AWS_ACCESS_KEY_ID", "User")
```
Si devuelve un valor (ej: `ASIA...`), esas son las credenciales expiradas.

**Solución:**
```powershell
[System.Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID",     $null, "User")
[System.Environment]::SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", $null, "User")
[System.Environment]::SetEnvironmentVariable("AWS_SESSION_TOKEN",     $null, "User")
```
Luego reinicia Visual Studio. Ver guía completa: [AWS_Token_Expired_Solution.md](AWS_Token_Expired_Solution.md#si-hiciste-login-pero-el-error-sigue-igual)
### ? Error: "Warning: AWS credentials not found"
1. Verifica `launchSettings.json` tiene `AWS_PROFILE`
2. O configura variable de usuario y **reinicia VS**:
   ```powershell
   [System.Environment]::SetEnvironmentVariable("AWS_PROFILE", "MI-PERFIL", "User")
   ```

### ? Error: "ResourceNotFoundException" (secreto no encontrado)
1. Verifica el nombre en `appsettings.json`
2. Confirma que tu rol tiene permisos `secretsmanager:GetSecretValue`
3. Contacta infraestructura para solicitar acceso

### ? Error: "Unable to locate credentials"
```powershell
aws configure sso --profile MI-PERFIL
```

### ? Visual Studio no toma las variables de entorno
- Reinicia Visual Studio completamente
- O ejecuta VS desde una terminal con las variables configuradas:
  ```powershell
  $env:AWS_PROFILE = "MI-PERFIL"
  & "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe"
  ```

## Comandos utiles

```powershell
# Ver perfiles configurados
aws configure list-profiles

# Ver información de la sesión actual
aws sts get-caller-identity --profile MI-PERFIL

# Listar secretos disponibles
aws secretsmanager list-secrets --profile MI-PERFIL --region us-east-1

# Obtener valor de un secreto
aws secretsmanager get-secret-value --secret-id "/ruta/secreto" --profile MI-PERFIL

# Verificar variable de entorno en PowerShell
echo $env:AWS_PROFILE
[System.Environment]::GetEnvironmentVariable("AWS_PROFILE", "User")

# Configurar variable temporal (solo sesión actual)
$env:AWS_PROFILE = "MI-PERFIL"
$env:AWS_REGION = "us-east-1"
```

## Referencias

- **Documentación completa:** [prompts/06_AWS_SSO_Setup.md](prompts/06_AWS_SSO_Setup.md)
- **Database Setup:** [prompts/05a_Database_Setup.md](prompts/05a_Database_Setup.md)
- **Troubleshooting:** [prompts/05d_Database_CICD_Troubleshooting.md](prompts/05d_Database_CICD_Troubleshooting.md)

---

**Última actualización:** Enero 2025
