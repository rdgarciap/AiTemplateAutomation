  AWS Token Expirado - Guía de Solución Rápida

   ?? Síntoma

Ves este error al ejecutar tests:

```
? AWS SSO token has expired!
?? Solution: Run 'aws sso login --profile BOA-DEV'
   Error: The security token included in the request is expired
=== AWS Session Validation FAILED ===
```

   ? Esto NO es un Error del Template

**¡El sistema está funcionando correctamente!** El framework detecta que tu token AWS expiró **antes** de ejecutar los tests, evitando fallos confusos más adelante.

---

   ?? SoluciÓn en 3 Pasos

    **Paso 1: Renovar el Token AWS**

Abre PowerShell y ejecuta:

```powershell
aws sso login --profile BOA-DEV
```

Esto abrirá tu navegador para autenticarte. Después de autenticarte, el token se renovará.

    **Paso 2: Verificar que Funciona**

```powershell
aws sts get-caller-identity --profile BOA-DEV
```

Deberás ver tu información de cuenta sin errores:

```json
{
    "UserId": "AROAQZ...:tu-usuario@dominio.com",
    "Account": "055587831261",
    "Arn": "arn:aws:sts::..."
}
```

    **Paso 3: Reiniciar Visual Studio**

**IMPORTANTE:** Visual Studio cachea las credenciales cuando inicia. Aunque renovaste el token, VS no lo detectará automáticamente.

**Opciones:**

**A. Reiniciar Visual Studio (MÁs Confiable)**
1. Cierra Visual Studio completamente
2. Vuelve a abrirlo
3. Ejecuta tus tests

**B. Ejecutar desde Terminal (Sin Reiniciar)**
```powershell
  En PowerShell, dentro de la carpeta del proyecto
cd "src/$ProjectName"
dotnet test
```

---

   ?? ¿Por Qué Pasa Esto?

Los tokens de AWS SSO **expiran cada 8 horas** por seguridad. Es comportamiento normal de AWS.

    Flujo Típico:

```
07:00 AM - Login inicial
   ??> Token válido por 8 horas

03:00 PM - Token expira automáticamente
   ??> ? Tests fallan si intentas ejecutar

03:01 PM - Renovar token
   ??> aws sso login --profile BOA-DEV
   ??> ? Token válido por 8 horas más
```

---

   ?? Ventajas de la Validación Temprana

    **Sin Validación (Antes):**
```
Test 1: PASS
Test 2: PASS
Test 3: Intenta conectar a AWS...
  ??> ? ExpiredToken
Test 4: No ejecuta (suite abortada)
Test 5: No ejecuta
```
? Pierdes tiempo ejecutando tests que fallarón
? Error aparece tarde, sin contexto claro

    **Con Validación (Ahora):**
```
BeforeTestRun:
  ??> Validando AWS...
  ??> ? Token expirado
  ??> Muestra solución clara
  ??> Tests NO ejecutan (ahorra tiempo)
```
? Detecta el problema ANTES de ejecutar tests
? Mensaje claro con solución
? Ahorras tiempo

---

   ??? Comandos Útiles

    Ver perfiles configurados
```powershell
aws configure list-profiles
```

    Ver perfil activo
```powershell
echo $env:AWS_PROFILE
```

    Configurar perfil (primera vez)
```powershell
aws configure sso --profile MI-PERFIL
```

    Renovar token (diario)
```powershell
aws sso login --profile MI-PERFIL
```

    Verificar token
```powershell
aws sts get-caller-identity --profile MI-PERFIL
```

---

   ?? Notas Importantes

1. **Tokens duran 8 horas** - Es normal renovar 1-2 veces al día
2. **Visual Studio debe reiniciarse** - Después de renovar el token
3. **El error es preventivo** - Ahorra tiempo al detectar problemas temprano
4. **No afecta producción** - En CI/CD, los tokens se manejan automáticamente

---
   🔁 Si Hiciste Login Pero el Error Sigue Igual

    Síntoma específico

Hiciste `aws sso login` correctamente, `aws sts get-caller-identity` funciona desde la terminal, pero los tests siguen fallando con `ExpiredToken`. En los logs aparece:

```
AWS_ACCESS_KEY_ID: SET
❌ AWS SSO token has expired!
   Error: The security token included in the request is expired
```

    Causa

Hay credenciales estáticas **expiradas** guardadas como variables de entorno permanentes de Windows (a nivel de usuario). Estas tienen **mayor prioridad** que el perfil SSO en la cadena de resolución del SDK, por lo que el SDK las usa aunque estén vencidas, ignorando el token fresco del login.

Esto ocurre cuando en algún momento anterior se usó el workaround de `aws configure export-credentials` y los valores se guardaron directamente como variables de entorno de Windows con `SetEnvironmentVariable(..., "User")` en lugar de en `launchSettings.json`.

    Solución: Eliminar las credenciales estáticas de Windows

Ejecuta en PowerShell:

```powershell
[System.Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID",     $null, "User")
[System.Environment]::SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", $null, "User")
[System.Environment]::SetEnvironmentVariable("AWS_SESSION_TOKEN",     $null, "User")
```

Verifica que se eliminaron:

```powershell
[System.Environment]::GetEnvironmentVariable("AWS_ACCESS_KEY_ID", "User")       debe devolver vacío
[System.Environment]::GetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", "User")   debe devolver vacío
[System.Environment]::GetEnvironmentVariable("AWS_SESSION_TOKEN", "User")       debe devolver vacío
```

Luego **reinicia Visual Studio** y ejecuta los tests. El SDK resolverá las credenciales desde el perfil SSO `BOA-DEV` con el token fresco.

    Verificar también a nivel de máquina

Si el problema persiste, comprueba también las variables a nivel de **Machine** (requiere PowerShell como administrador):

```powershell
[System.Environment]::GetEnvironmentVariable("AWS_ACCESS_KEY_ID", "Machine")
[System.Environment]::GetEnvironmentVariable("AWS_SESSION_TOKEN", "Machine")
```

Si tienen valor, elimínalas:

```powershell
  Ejecutar como Administrador
[System.Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID",     $null, "Machine")
[System.Environment]::SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", $null, "Machine")
[System.Environment]::SetEnvironmentVariable("AWS_SESSION_TOKEN",     $null, "Machine")
```

---
   ?? Si el Problema Persiste

    Verifica launchSettings.json

Archivo: `src/<ProjectName>/Properties/launchSettings.json`

Debe contener:
```json
{
  "profiles": {
    "<ProjectName>": {
      "environmentVariables": {
        "AWS_PROFILE": "BOA-DEV",
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

    Verifica Variables de Entorno

En PowerShell:
```powershell
echo $env:AWS_PROFILE      Debe mostrar: BOA-DEV
echo $env:AWS_REGION       Debe mostrar: us-east-1
```

Si están vacías, configúralas:
```powershell
$env:AWS_PROFILE = "BOA-DEV"
$env:AWS_REGION = "us-east-1"
```

    Ejecutar Test de Diagnóstico

En Test Explorer, ejecuta:
```
AwsConnectionTest > TestAwsSessionValidation
```

Este test te dirá exactamente qué está mal.

---

   ? Checklist de Solución

- [ ] Ejecuta `aws sso login --profile BOA-DEV`
- [ ] Verifique con `aws sts get-caller-identity --profile BOA-DEV`- [ ] Comprobé que NO hay credenciales estáticas en variables de entorno de Windows (`AWS_ACCESS_KEY_ID` a nivel User/Machine)- [ ] Reinició Visual Studio completamente
- [ ] Ejecutó los tests de nuevo
- [ ] ? Tests ahora pasan

---

   ?? Referencias

- **Configuración AWS SSO:** [prompts/06_AWS_SSO_Setup.md](../prompts/06_AWS_SSO_Setup.md)
- **Template AWS:** [prompts/07_AWS_Integration_Template.md](../prompts/07_AWS_Integration_Template.md)
- **Checklist Rápido:** [AWS_SSO_Quick_Checklist.md](AWS_SSO_Quick_Checklist.md)- **Workaround SDK .NET:** [AWS_SSO_Workaround_DotNet.md](AWS_SSO_Workaround_DotNet.md)
---

**Última actualización:** Enero 2025  
**Aplica a:** Todos los proyectos con AWS SSO
