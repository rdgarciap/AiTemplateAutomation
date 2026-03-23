# DemoFinancialServicesQA — Paquete Documental del Template

Este repositorio contiene la especificacion documental para construir el template
`<ProjectName>` (por defecto `DemoFinancialServicesQA`), un framework BDD de automatizacion QA con IA basado en
.NET 8, Semantic Kernel, Reqnroll y NUnit.

En el estado actual del workspace, el repositorio actua como **paquete de prompts y guias**.
La carpeta `src/<ProjectName>/` es la **salida objetivo** del proceso de generacion,
no un proyecto ya incluido en este repositorio.

La forma operativa recomendada para materializar esa salida es ejecutar [bootstrap-template.ps1](bootstrap-template.ps1).

**Stack objetivo:** .NET 8 · Semantic Kernel · Reqnroll (BDD) · NUnit  
**Salida objetivo:** `src/<ProjectName>/`

> Nota: `DemoFinancialServicesQA` es el nombre por defecto del template.
> Para generar un proyecto con otro nombre, usa `-ProjectName` en el bootstrap.

---

## Qué contiene este repositorio

- documentacion normativo-tecnica del template
- guias de implementacion por componente
- referencias operativas para base de datos, CI/CD y troubleshooting
- archivos de soporte del repositorio (`build/`, `.github/`, `NuGet.Config`)

La entrada principal para navegar la documentacion es [prompts/README.md](prompts/README.md).

---

## Configuración de Acceso al Feed Privado

El proyecto consume `Gbm.Automation.Core` desde el feed privado de GitHub Packages (`gbmWallE`).
Para que `dotnet restore` funcione localmente es necesario que `VSTS_GITHUB_ACCESS_KEY` esté
disponible como variable de entorno en la sesión actual de la terminal.

> **Problema conocido:** VS Code abre terminales como procesos hijo del editor, que en Windows
> NO heredan variables configuradas en el ámbito de *Usuario* del sistema.
> El token puede estar en tu sistema y aun así `dotnet restore` fallará con `401 Unauthorized`.

### Inyección manual en la terminal

Si prefieres ejecutar los pasos por separado:

```powershell
# 1. Leer el token desde el ámbito de Usuario y exponerlo en la sesión actual
$env:VSTS_GITHUB_ACCESS_KEY = [System.Environment]::GetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "User")

# 2. Verificar que se inyectó correctamente (debe mostrar el token, no estar vacío)
echo $env:VSTS_GITHUB_ACCESS_KEY

# 3. Restaurar y compilar
cd "src/$ProjectName"
dotnet restore
dotnet build --configuration Release
```

> Si `$env:VSTS_GITHUB_ACCESS_KEY` queda vacio, el token no esta configurado a nivel de Usuario.
> Configúralo con: `[System.Environment]::SetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "ghp_TU_TOKEN", "User")`

---

## Inicio Rápido

### Prerrequisitos

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8) instalado
- Visual Studio 2022+ o Visual Studio Code con extensión C#
- Una API Key de OpenAI o Azure OpenAI
- Variable de entorno `VSTS_GITHUB_ACCESS_KEY` configurada (ver sección anterior)
- **[AWS CLI v2](https://aws.amazon.com/cli/)** instalado y configurado con AWS SSO (ver [prompts/06_AWS_SSO_Setup.md](prompts/06_AWS_SSO_Setup.md))
- Si vas a consumir AWS Secrets Manager para base de datos, una sesión activa de AWS SSO (`aws sso login`)

### Pasos

1. **Configurar AWS SSO (si aplica)**

Si tu proyecto usa AWS Secrets Manager para credenciales de base de datos:

```powershell
# Configurar perfil (primera vez)
aws configure sso --profile TU-PERFIL

# Hacer login (diario o cada 8 horas)
aws sso login --profile TU-PERFIL

# Verificar sesión
aws sts get-caller-identity --profile TU-PERFIL
```

📋 **Quick Reference:** [docs/AWS_SSO_Quick_Checklist.md](docs/AWS_SSO_Quick_Checklist.md)  
📘 **Documentación completa:** [prompts/06_AWS_SSO_Setup.md](prompts/06_AWS_SSO_Setup.md)

2. Generar el proyecto base

Usa [bootstrap-template.ps1](bootstrap-template.ps1) desde la raiz del repositorio:

```powershell
$ProjectName = "MiProyectoQA"
.\bootstrap-template.ps1 -ProjectName $ProjectName -SkipRestore
```

Si necesitas incluir el scaffold de base de datos y paquetes privados:

```powershell
.\bootstrap-template.ps1 -ProjectName $ProjectName -UsePrivatePackages -IncludeDatabase -SkipRestore
```

`-SkipRestore` permite materializar la salida aun cuando todavia no hayas configurado secretos o acceso al feed privado.

3. Revisar el mapa documental

Lee [prompts/README.md](prompts/README.md) para identificar:

- documentos normativos
- documentos de implementacion
- referencias operativas

4. Seguir el plan maestro

Usa [prompts/00_Agent_Execution_Plan.md](prompts/00_Agent_Execution_Plan.md) como orden oficial de ensamblaje.

5. Verificar la salida objetivo

El bootstrap debe producir, como minimo, el archivo `src/<ProjectName>/<ProjectName>.csproj` y su carpeta asociada.

Ejemplo con nombre por defecto: [src/DemoFinancialServicesQA/DemoFinancialServicesQA.csproj](src/DemoFinancialServicesQA/DemoFinancialServicesQA.csproj).

Ruta objetivo: `src/<ProjectName>/`.

6. Configurar la API Key y la cadena de conexión

Cuando la salida exista, edita `src/<ProjectName>/appsettings.json` y reemplaza los placeholders.

Ejemplo con nombre por defecto: [src/DemoFinancialServicesQA/appsettings.json](src/DemoFinancialServicesQA/appsettings.json).

```json
```json
{
  "AWSSettings": {
    "Region": "us-east-1",
    "Secrets": {
      "SobConnectionString": "/gbm/boa/project/sqlserver-credentials"
    }
  },
  "AiSettings": {
    "Mode": "online",
    "OpenAI": {
      "ApiKey": "sk-tu-api-key-real-aqui",
      "ModelId": "gpt-4o"
    }
  }
}
```
> ⚠️ Nunca comitees el archivo con una ApiKey real. Usa variables de entorno en CI/CD.

7. Restaurar y compilar

```powershell
# Inyectar el token de acceso al feed privado en la sesión actual
$env:VSTS_GITHUB_ACCESS_KEY = [System.Environment]::GetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "User")

cd "src/$ProjectName"
dotnet restore
dotnet build --configuration Release
```

8. Ejecutar los tests de ejemplo
```bash
dotnet test --configuration Release
```

9. Escribir tu primer escenario

Abre `src/<ProjectName>/Features/Sample.feature` y agrega.

Ejemplo con nombre por defecto: [src/DemoFinancialServicesQA/Features/Sample.feature](src/DemoFinancialServicesQA/Features/Sample.feature).

```gherkin
Scenario: Mi primer test con IA
  When I instruct the AI to "navigate to https://mi-app.com"
  Then the AI action should succeed
```

---

## Solución de Problemas Comunes

### AWS SSO: Token expirado durante el debug

**Síntoma:** Error `ExpiredToken` al ejecutar tests con base de datos o servicios AWS.

**Solución:**
```powershell
# Renovar sesión AWS (tokens expiran cada 8 horas)
aws sso login --profile TU-PERFIL

# Verificar
aws sts get-caller-identity --profile TU-PERFIL
```

**Nota:** El template ahora valida la sesión AWS **automáticamente** en `BeforeTestRun`. Si ves un warning al inicio, ejecuta el comando de arriba.

Ver guías completas:
- [prompts/06_AWS_SSO_Setup.md](prompts/06_AWS_SSO_Setup.md) - Configuración de AWS SSO
- [prompts/07_AWS_Integration_Template.md](prompts/07_AWS_Integration_Template.md) - Template de implementación AWS

### Visual Studio no encuentra credenciales AWS

**Causa:** Visual Studio no hereda variables de entorno de la terminal.

**Solución:** Agrega `Properties/launchSettings.json`:
```json
{
  "profiles": {
    "<ProjectName>": {
      "environmentVariables": {
        "AWS_PROFILE": "TU-PERFIL",
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

### Error 401 al restaurar paquetes

**Causa:** Variable `VSTS_GITHUB_ACCESS_KEY` no disponible en la sesión.

**Solución:**
```powershell
$env:VSTS_GITHUB_ACCESS_KEY = [System.Environment]::GetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "User")
dotnet restore
```

---

## Documentación del Template

| Archivo | Contenido |
|---|---|
| [prompts/README.md](prompts/README.md) | Mapa de lectura y taxonomia documental |
| [prompts/00_Agent_Execution_Plan.md](prompts/00_Agent_Execution_Plan.md) | Plan maestro de ensamblaje |
| [prompts/01_Stack_Setup.md](prompts/01_Stack_Setup.md) | Contrato tecnico base del template |
| [prompts/02_Architecture_Layout.md](prompts/02_Architecture_Layout.md) | Contrato de arquitectura |
| [prompts/02a_Core_Implementation.md](prompts/02a_Core_Implementation.md) | Implementacion sugerida del core |
| [prompts/03_Skills_Extensibility.md](prompts/03_Skills_Extensibility.md) | Estandar de skills |
| [prompts/03a_Skills_Implementation.md](prompts/03a_Skills_Implementation.md) | Implementacion sugerida de skills base |
| [prompts/04_Prompt_Engineering.md](prompts/04_Prompt_Engineering.md) | Contrato del orquestador AI |
| [prompts/04a_Orchestrator_Implementation.md](prompts/04a_Orchestrator_Implementation.md) | Implementacion sugerida del orquestador |
| [prompts/05_Database_Skill.md](prompts/05_Database_Skill.md) | Hub del dominio de base de datos |
| [prompts/05a_Database_Setup.md](prompts/05a_Database_Setup.md) | Setup operativo de BD |
| [prompts/05b_Database_Steps_Reference.md](prompts/05b_Database_Steps_Reference.md) | Catalogo funcional de pasos BD |
| [prompts/05c_Database_Scenario_Patterns.md](prompts/05c_Database_Scenario_Patterns.md) | Patrones de escenarios BD |
| [prompts/05d_Database_CICD_Troubleshooting.md](prompts/05d_Database_CICD_Troubleshooting.md) | CI/CD y troubleshooting BD |
| [prompts/05e_Database_Implementation.md](prompts/05e_Database_Implementation.md) | Implementacion sugerida de DB |
| [prompts/06_AWS_SSO_Setup.md](prompts/06_AWS_SSO_Setup.md) | Configuración de AWS SSO para CLI |

---

## Actualización de Versión de .NET

Cuando .NET 8 quede descontinuado, cambia estos 3 lugares:

1. `src/<ProjectName>/<ProjectName>.csproj` → `<TargetFramework>net9.0</TargetFramework>`
2. [build/buildspec-build.yml](build/buildspec-build.yml) → `dotnet: 9.0`
3. Versiones de `Microsoft.Extensions.Configuration.Json` y `Microsoft.Extensions.DependencyInjection` NuGet → `9.0.x`

> `Microsoft.Extensions.Configuration.EnvironmentVariables` tiene numeracion propia
> en nuget.org; verifica la ultima version disponible antes de cambiarla.

Ver la guia completa en [prompts/01_Stack_Setup.md](prompts/01_Stack_Setup.md).