# AWS SSO Workaround para .NET SDK

## ⚠️ ¿Cuándo aparece este error?

Ves este mensaje en los logs de validación:

```
❌ AWS SDK error: ...
⚠️ WORKAROUND for .NET SDK SSO issue:
   The AWS SDK for .NET has limited SSO support. Use this workaround:
=== AWS Session Validation FAILED ===
```

---

## 🔍 Causa Raíz

El **AWS SDK para .NET** (v4.x) tiene soporte limitado para perfiles SSO configurados con el modelo de `sso-session` de la AWS CLI v2. Aunque tu sesión `aws sso login` esté activa y comandos como `aws sts get-caller-identity` funcionen desde la terminal, el SDK de .NET puede fallar al leer las credenciales directamente desde los archivos de caché SSO.

Esto ocurre porque el SDK de .NET **no implementa el flujo completo de refresh de tokens SSO** que sí tiene la AWS CLI v2.

---

## ✅ Solución 1: Exportar credenciales temporales (Recomendada)

Este método inyecta credenciales de corta duración directamente en las variables de entorno del proyecto, sin cambiar la configuración global.

### Paso 1 — Exportar las credenciales desde AWS CLI

Abre **PowerShell** y ejecuta:

```powershell
aws configure export-credentials --profile BOA-DEV --format env-no-export
```

La salida tiene este formato:

```
AWS_ACCESS_KEY_ID=ASIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjEA....(token muy largo)....
```

### Paso 2 — Copiar los valores a `launchSettings.json`

Edita el archivo `src/<ProjectName>/Properties/launchSettings.json`:

```json
{
  "profiles": {
    "<ProjectName>": {
      "commandName": "Project",
      "environmentVariables": {
        "AWS_PROFILE": "BOA-DEV",
        "AWS_REGION": "us-east-1",
        "AWS_SDK_LOAD_CONFIG": "1",
        "AWS_ACCESS_KEY_ID": "ASIAXXXXXXXXXXXXXXXX",
        "AWS_SECRET_ACCESS_KEY": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "AWS_SESSION_TOKEN": "IQoJb3JpZ2luX2VjEA...."
      }
    }
  }
}
```

### Paso 3 — Reiniciar Visual Studio

Cierra y vuelve a abrir Visual Studio. Al arrancar, tomará las nuevas variables de entorno.

### ⚠️ Limitaciones de este método

- Las credenciales temporales **expiran** (típicamente en 1 hora para roles asumidos vía SSO).
- Debes repetir los pasos 1 y 2 cada vez que expiren.
- **Nunca comitees `launchSettings.json` con credenciales reales.** El archivo ya está en `.gitignore` por el template del proyecto.

### 🚨 Error crítico a evitar: guardar credenciales como variables de entorno de Windows

**NUNCA** uses `[System.Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID", "...", "User")` para guardar las credenciales exportadas. Las variables de entorno de Windows a nivel de usuario **persisten indefinidamente** entre reinicios del sistema, pero las credenciales temporales de SSO **expiran en ~1 hora**.

Cuando las credenciales en las variables de Windows expiran, el SDK de .NET las sigue usando (porque tienen mayor prioridad que el perfil SSO), lo que produce el error `ExpiredToken` incluso después de hacer `aws sso login`. Este es un error difícil de diagnosticar porque la CLI funciona perfectamente desde la terminal pero Visual Studio falla.

**Si accidentalmente guardaste credenciales como variables de entorno de usuario, límpialas así:**

```powershell
[System.Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID",     $null, "User")
[System.Environment]::SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", $null, "User")
[System.Environment]::SetEnvironmentVariable("AWS_SESSION_TOKEN",     $null, "User")
```

✅ **Correcto:** Copia las credenciales exportadas **únicamente** a `launchSettings.json` (que es local y no se commitea).

---

## ✅ Solución 2: Variable `AWS_SDK_LOAD_CONFIG`

En algunos casos el problema es que el SDK de .NET no carga el archivo `~/.aws/config`. Asegúrate de que `launchSettings.json` tenga esta variable:

```json
"AWS_SDK_LOAD_CONFIG": "1"
```

Esto fuerza al SDK de .NET a leer el archivo de configuración de la CLI. Si ya está configurado (el template lo incluye por defecto) y el error persiste, usa la Solución 1.

---

## ✅ Solución 3: Ejecutar los tests desde terminal (Sin reiniciar VS)

Si no quieres reiniciar Visual Studio, puedes ejecutar los tests directamente desde PowerShell, donde las credenciales SSO ya están activas:

```powershell
# Desde la raíz del repositorio
cd "src/$ProjectName"
$env:AWS_PROFILE = "BOA-DEV"
$env:AWS_REGION = "us-east-1"
dotnet test
```

La AWS CLI v2 en la terminal tiene soporte SSO completo, a diferencia del SDK embebido en el proceso de Visual Studio.

---

## 🔄 Script de ayuda — Copiar credenciales al portapapeles

Para agilizar el proceso de la Solución 1, puedes usar este script de PowerShell que genera el bloque JSON listo para pegar en `launchSettings.json`:

```powershell
$creds = aws configure export-credentials --profile BOA-DEV --format env-no-export
$lines = $creds -split "`n"
$keyId     = ($lines | Where-Object { $_ -match "AWS_ACCESS_KEY_ID" }) -replace "AWS_ACCESS_KEY_ID=",""
$secret    = ($lines | Where-Object { $_ -match "AWS_SECRET_ACCESS_KEY" }) -replace "AWS_SECRET_ACCESS_KEY=",""
$token     = ($lines | Where-Object { $_ -match "AWS_SESSION_TOKEN" }) -replace "AWS_SESSION_TOKEN=",""

$json = @"
        "AWS_ACCESS_KEY_ID": "$keyId",
        "AWS_SECRET_ACCESS_KEY": "$secret",
        "AWS_SESSION_TOKEN": "$token"
"@

$json | Set-Clipboard
Write-Host "✅ Credenciales copiadas al portapapeles. Pégalas en launchSettings.json"
```

---

## 🧪 Verificar que el workaround funcionó

Después de configurar las credenciales y reiniciar, ejecuta el test de diagnóstico en el **Test Explorer**:

```
Tests/AwsConnectionTest > TestAwsSessionValidation
```

O directamente desde terminal:

```powershell
dotnet test --filter "FullyQualifiedName~AwsConnectionTest"
```

Debes ver en los logs:

```
✅ AWS Session Valid!
   Account: 055587831261
   UserId: AROAQZ...:tu-usuario@dominio.com
   Arn: arn:aws:sts::...
=== AWS Session Validation SUCCESS ===
```

---

## 🔐 Seguridad: Protección de credenciales temporales

`launchSettings.json` **no debe subirse al repositorio**. Verifica que está en `.gitignore`:

```powershell
git check-ignore -v "src/$ProjectName/Properties/launchSettings.json"
```

Si no aparece como ignorado, agrégalo:

```powershell
Add-Content .gitignore "`nsrc/<ProjectName>/Properties/launchSettings.json"
```

---

## 📊 Comparación de métodos

| Método | Frecuencia de renovación | Reinicio VS | Recomendado para |
|---|---|---|---|
| Export a launchSettings.json | ~1 hora | Sí | Desarrollo intensivo con VS |
| Variable `AWS_SDK_LOAD_CONFIG` | No aplica | Sí | Primer intento, más simple |
| Ejecutar desde terminal | No necesita | No | Ejecuciones puntuales de tests |

---

## 📚 Referencias

- **Guía completa AWS SSO:** [prompts/06_AWS_SSO_Setup.md](../prompts/06_AWS_SSO_Setup.md)
- **Token expirado:** [AWS_Token_Expired_Solution.md](AWS_Token_Expired_Solution.md)
- **Checklist diario:** [AWS_SSO_Quick_Checklist.md](AWS_SSO_Quick_Checklist.md)

---

**Última actualización:** Marzo 2026
**Aplica a:** AWS SDK .NET v4, AWS CLI v2, .NET 8
