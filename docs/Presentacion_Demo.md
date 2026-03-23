---
marp: true
theme: default
paginate: true
backgroundColor: "#0f1117"
color: "#e8eaf6"
style: |
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
    font-size: 22px;
    padding: 40px 60px;
  }
  h1 {
    color: #7c9cff;
    font-size: 1.9em;
    border-bottom: 2px solid #7c9cff;
    padding-bottom: 10px;
    margin-bottom: 20px;
  }
  h2 {
    color: #a5c8ff;
    font-size: 1.4em;
    margin-bottom: 10px;
  }
  h3 {
    color: #c8d8ff;
    font-size: 1.1em;
  }
  strong {
    color: #90caf9;
  }
  em {
    color: #b0bec5;
  }
  code {
    background: #1e2235;
    color: #80cbc4;
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 0.85em;
  }
  pre {
    background: #1a1f2e;
    border-left: 4px solid #7c9cff;
    border-radius: 8px;
    padding: 16px;
    font-size: 0.78em;
  }
  pre code {
    background: transparent;
    padding: 0;
    font-size: 1em;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.85em;
  }
  th {
    background: #1e2a4a;
    color: #7c9cff;
    padding: 8px 12px;
    text-align: left;
    border-bottom: 2px solid #7c9cff;
  }
  td {
    padding: 7px 12px;
    border-bottom: 1px solid #2a3050;
  }
  tr:nth-child(even) td {
    background: #131825;
  }
  ul {
    line-height: 1.8;
  }
  li {
    margin-bottom: 4px;
  }
  .columns {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 30px;
  }
  .columns3 {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 20px;
  }
  .card {
    background: #1a1f2e;
    border: 1px solid #2a3a6a;
    border-radius: 10px;
    padding: 14px 18px;
    margin-bottom: 12px;
  }
  .tag-green  { color: #69f0ae; font-weight: bold; }
  .tag-yellow { color: #ffd740; font-weight: bold; }
  .tag-red    { color: #ff5252; font-weight: bold; }
  .tag-blue   { color: #82b1ff; font-weight: bold; }
  .tag-teal   { color: #64ffda; font-weight: bold; }
  .pill {
    display: inline-block;
    background: #1e2a4a;
    border: 1px solid #3a4a7a;
    border-radius: 20px;
    padding: 3px 12px;
    font-size: 0.75em;
    margin: 3px;
  }
  section.title {
    background: linear-gradient(135deg, #0d1424 0%, #0f1f3d 50%, #0d1424 100%);
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }
  section.title h1 {
    font-size: 2.4em;
    border: none;
    color: #7c9cff;
    text-shadow: 0 0 30px rgba(124,156,255,0.4);
  }
  section.divider {
    background: linear-gradient(135deg, #0d1424 0%, #0f1f3d 100%);
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }
  section.divider h1 {
    border: none;
    font-size: 2.2em;
  }
---

<!-- _class: title -->

# QA Automation con Inteligencia Artificial
## Template de Ai

---

# Agenda

1. **El Problema** — Por qué el QA tradicional no escala
2. **La Solución** — Qué es este template
3. **Arquitectura** — Cómo está construido
4. **Stack Tecnológico** — Herramientas y por qué cada una
5. **Flujo de Trabajo** — De Gherkin a ejecución IA
6. **Integración AWS** — Seguridad y secretos
7. **Beneficios** — Para el equipo y para la empresa
8. **Casos de Uso** — Aplicabilidad en GBM
9. **Riesgos y Mitigaciones**
10. **Plan de Implementación** — Cómo adoptarlo
11. **Mantenimiento y Evolución**
12. **Conclusión**

---

<!-- _class: divider -->

# Parte 1
## El Problema

---

# El QA Manual y Semi-Manual No Escala

<div class="columns">
<div>

**Situación actual típica:**

- Tests manuales repetitivos por cada release
- Scripts de automatización frágiles ante cambios
- Cobertura de pruebas inconsistente entre proyectos
- Sin estándar: cada equipo usa su propia solución
- Conocimiento de automatización concentrado en 1–2 personas
- Tiempo de onboarding alto para nuevos QAs

</div>
<div>

**Consecuencias:**

<div class="card">
⏳ <strong>Velocity</strong> — releases bloqueados esperando ciclos de QA manuales
</div>
<div class="card">
💸 <strong>Costo</strong> — re-trabajo elevado por bugs escapados a producción
</div>
<div class="card">
🔄 <strong>Consistencia</strong> — calidad variable entre proyectos y equipos
</div>
<div class="card">
📉 <strong>Cobertura</strong> — escenarios críticos sin prueba automatizada
</div>

</div>
</div>

---

# La Brecha: IA en el Negocio vs. IA en QA

> Los equipos de desarrollo ya usan IA (Copilot, ChatGPT) para escribir código.
> **¿Por qué el proceso de QA continúa siendo 100% manual o scriptado a mano?**

<div class="columns">
<div>

**Sin IA en QA:**
```gherkin
# El QA escribe el feature...
When I instruct the AI to "navigate to login"
# ...y TAMBIÉN debe:
# - escribir el selector CSS exacto
# - mantenerlo si cambia la UI
# - re-ejecutar manualmente si falla
```

</div>
<div>

**Con IA en QA:**
```gherkin
# El QA solo describe la intención:
When I instruct the AI to "navigate to login"

# El orquestador IA resuelve:
# → skill: Browser
# → function: NavigateTo
# → args: { "url": "/login" }
```

</div>
</div>

**El template que presentamos cierra esta brecha.**

---

<!-- _class: divider -->

# Parte 2
## La Solución

---

# ¿Qué es AiTemplateAutomation?

Un **template de framework BDD con orquestación IA**, listo para ser utilizado directamente por el QA.

<div class="columns">
<div>

**Lo que es:**
- Un template generador (`bootstrap-template.ps1`)
- Un framework de pruebas con arquitectura definida
- Una colección de skills reutilizables (Browser, API, Database)
- Un contrato técnico documentado (prompts/)
- Integración nativa con AWS (SSO, Secrets Manager)

</div>
<div>

**Lo que NO es:**
- Un proyecto de pruebas específico de un sistema
- Un reemplazo de criterios de aceptación del negocio
- Una solución mágica sin configuración
- Una herramienta que requiere conocer IA profundamente

</div>
</div>

> **En 1 comando** se genera un proyecto .NET 8 compilable, con BDD, IA y AWS configurados y listos para escribir escenarios.

---

# Filosofía de Diseño

```
Instrucción en lenguaje natural  →  Orquestador IA  →  Skill concreta  →  Resultado
```

El QA se enfoca en **qué** debe pasar. La IA decide **cómo** ejecutarlo.

| Principio | Implementación |
|---|---|
| **BDD primero** | Reqnroll + Gherkin — escenarios legibles por el negocio |
| **IA como herramienta, no como oráculo** | El LLM selecciona skills; el QA valida resultados |
| **Determinismo en CI** | Temperatura `0.0` — respuestas reproducibles |
| **Seguridad por diseño** | Secretos vía AWS Secrets Manager, nunca en código |
| **Un estándar, múltiples proyectos** | Un bootstrap genera cualquier proyecto corporativo |
| **Código limpio** | StyleCop + FXCop + XML docs — mantenible y auditable |

---

<!-- _class: divider -->

# Parte 3
## Arquitectura

---

# Arquitectura de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PROYECTO GENERADO                            │
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────────────────┐  │
│  │  Features/   │    │    Hooks/    │    │   StepDefinitions/    │  │
│  │  *.feature   │───▶│  Lifecycle  │    │  AiOrchestratorSteps  │  │
│  │  (Gherkin)   │    │  (DI Setup) │    │  DatabaseStepDefs     │  │
│  └──────────────┘    └──────┬───────┘    └───────────┬───────────┘  │
│                             │                        │              │
│                    ┌────────▼────────┐               │              │
│                    │   Semantic      │◀──────────────┘              │
│                    │   Kernel        │                              │
│                    └────────┬────────┘                              │
│                             │ plugins                               │
│           ┌─────────────────┼─────────────────┐                    │
│           ▼                 ▼                  ▼                    │
│    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│    │ BrowserSkill │  │   ApiSkill   │  │DatabaseSkill │            │
│    └──────────────┘  └──────────────┘  └──────┬───────┘            │
│                                                │                    │
│                           ┌────────────────────▼─────────────────┐  │
│                           │     AWS Secrets Manager / SQL Server │  │
│                           └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

# Componentes Core

| Componente | Responsabilidad | Alcance |
|---|---|---|
| `AiContext` | Estado compartido entre steps y skills | Por escenario |
| `ConfigurationDriver` | Lectura tipada de `appsettings.json` + EnvVars | Por escenario |
| `TestLifecycleHooks` | Construcción del Kernel, registro de skills | Por escenario |
| `Kernel` (Semantic Kernel) | Punto de entrada para plugins y prompts | Por escenario |
| `BrowserSkill` | Automatización UI (Selenium/Playwright) | Registrada en Kernel |
| `ApiSkill` | HTTP GET / POST / Validación JSON | Registrada en Kernel |
| `DatabaseSkill` | Queries SQL, SPs, scripts | Registrada si DB configurada |
| `OrchestratorCommand` | DTO del JSON de respuesta del LLM | Por invocación |
| `AwsCredentialsProvider` | Resolución y caché de credenciales AWS | Singleton por sesión |
| `AwsSecretsManagerDriver` | Resolución de connection strings via secretos | Por escenario |

> **Regla de oro:** Ningún componente tiene estado mutable estático (excepto el caché de credenciales AWS, intencional por performance).

---

# Lifecycle por Escenario

```
Gherkin: Scenario: Verificar saldo de cuenta
          │
          ▼
 [BeforeScenario]
  1. new ConfigurationDriver()      ← lee appsettings.json + EnvVars
  2. new AiContext()                ← estado vacío
  3. AwsSecretsManagerDriver        ← prepara acceso a secretos
  4. Kernel.CreateBuilder()         ← construye orquestador IA
  5. BrowserSkill + ApiSkill        ← registra plugins base
  6. DatabaseSkill (si DB válida)   ← registra plugin DB (condicional)
          │
          ▼
 [Steps execution]
  When I instruct the AI to "..."  → AiOrchestratorSteps
  When I execute the SQL query     → DatabaseStepDefinitions
  Then the AI action should succeed
          │
          ▼
 [AfterScenario]
  - Libera browser/driver UI
  - Cierra conexiones abiertas
  - Limpia recursos externos
```

---

<!-- _class: divider -->

# Parte 4
## Stack Tecnológico

---

# Stack Tecnológico

<div class="columns">
<div>

**Capa de Pruebas**

| Paquete | Versión | Rol |
|---|---|---|
| `Reqnroll` | 2.4.0 | BDD / Gherkin runner |
| `Reqnroll.NUnit` | 2.4.0 | Integración con NUnit |
| `NUnit` | 4.2.2 | Assertions y Test engine |
| `NUnit3TestAdapter` | 4.6.0 | Discovery en IDE y CI |
| `Microsoft.NET.Test.Sdk` | 17.12.0 | Runner SDK |

**Inteligencia Artificial**

| Paquete | Versión | Rol |
|---|---|---|
| `Microsoft.SemanticKernel` | 1.30.0 | Orquestador LLM + plugins |
| `Newtonsoft.Json` | 13.0.4 | Parsing respuesta LLM |

</div>
<div>

**Infraestructura AWS**

| Paquete | Versión | Rol |
|---|---|---|
| `AWSSDK.Core` | 4.0.3 | Autenticación base |
| `AWSSDK.SSO` | 4.0.2 | AWS IAM Identity Center |
| `AWSSDK.SSOOIDC` | 4.0.3 | Flow de login SSO |
| `AWSSDK.SecurityToken` | 4.0.5 | STS / credenciales temporales |
| `AWSSDK.SecretsManager` | 4.0.2 | Secretos en vault |

**Base de Datos (opcional)**

| Paquete | Versión | Rol |
|---|---|---|
| `Gbm.Automation.Core` | 1.7.7 | Abstracciones DB (privado) |
| `Dapper` | 2.1.66 | ORM ligero / mappeo SQL |

</div>
</div>

---

# Por Qué Este Stack

<div class="columns">
<div>

**Reqnroll + NUnit**
- Sucesor oficial de SpecFlow (mismos autores)
- Living documentation: el feature file ES la especificación
- Detectado nativamente por Visual Studio y riders CI/CD

**Semantic Kernel**
- SDK oficial de Microsoft para LLM en .NET
- Soporte nativo OpenAI **y** Azure OpenAI
- Plugins tipados con descripción → el LLM entiende cuándo usarlos
- Temperatura `0.0` → comportamiento reproducible

</div>
<div>

**AWS SDK + SSO**
- Gestión de credenciales sin secrets en código
- Compatibilidad con el estándar corporativo de GBM
- Soporte para credenciales temporales (rotación automática)
- Resolución de connection strings desde Secrets Manager

**.NET 8**
- LTS (Long Term Support) hasta noviembre 2026
- `Nullable enable` + `ImplicitUsings` — código moderno y seguro
- Rendimiento superior vs .NET Framework

</div>
</div>

---

<!-- _class: divider -->

# Parte 5
## Flujo de Trabajo

---

# De Gherkin a Ejecución

**Paso 1: El QA escribe el escenario**

```gherkin
Feature: Consulta de portafolio

  @smoke @api
  Scenario: Obtener posiciones del cliente via AI
    When I instruct the AI to "call GET https://api.gbm.com/portfolio/positions?clientId=12345"
    Then the AI action should succeed

  @database @readonly
  Scenario: Verificar saldo en base de datos
    When I execute the SQL query "SELECT Balance FROM Accounts WHERE ClientId = 12345"
    Then the database query should return at least 1 row
```

**Paso 2: El orquestador IA procesa la instrucción**

```
Instrucción: "call GET https://api.gbm.com/portfolio/positions?clientId=12345"
     │
     ▼
LLM responde (temperatura 0.0):
{"skill":"Api","function":"GetRequest","args":{"url":"https://api.gbm.com/portfolio/positions?clientId=12345"}}
     │
     ▼
Kernel.InvokeAsync("Api", "GetRequest", {"url": "..."})
     │
     ▼
AiContext.LastSkillResult = "{\"positions\": [...]}"
```

---

# El Prompt del Orquestador

El archivo `Prompts/orchestrator.skprompt.txt` es el "cerebro" de la IA. Define:

```
You are an AI orchestrator for a test automation framework.
Your ONLY job is to select the correct skill and function.
Available skills: {{$available_skills}}

RULES:
- Respond ONLY with a single JSON object.
- JSON format: {"skill":"PluginName","function":"FunctionName","args":{...}}
- Use exact plugin and function names.

Instruction: "navigate to https://example.com"
Output: {"skill":"Browser","function":"NavigateTo","args":{"url":"https://example.com"}}

Instruction: "validate the response has fields id, name, email"
Output: {"skill":"Api","function":"ValidateJsonSchema","args":{"requiredFields":"id, name, email"}}

Instruction: "{{$instruction}}"
Output:
```

> El template incluye **2+ ejemplos por skill** (few-shot) para guiar al LLM hacia respuestas consistentes.

---

# Skills Disponibles

| Plugin | Función | Descripción |
|---|---|---|
| `Browser` | `NavigateTo` | Navega a una URL |
| `Browser` | `ClickElement` | Hace clic en un elemento (selector) |
| `Browser` | `FillField` | Escribe un valor en un campo |
| `Browser` | `GetElementText` | Lee el texto de un elemento |
| `Api` | `GetRequest` | HTTP GET y guarda la respuesta |
| `Api` | `PostRequest` | HTTP POST con body JSON |
| `Api` | `ValidateJsonSchema` | Valida campos requeridos en la respuesta |
| `Database` | `ExecuteQuery` | SELECT → retorna JSON de filas |
| `Database` | `ExecuteCommand` | INSERT/UPDATE/DELETE → filas afectadas |
| `Database` | `ExecuteStoredProcedure` | SP que retorna filas |
| `Database` | `ExecuteScriptFile` | Ejecuta archivo `.sql` |

> **Añadir una nueva skill** es tan simple como crear una clase con `[KernelFunction]` y registrarla en `TestLifecycleHooks`.

---

<!-- _class: divider -->

# Parte 6
## Integración AWS

---

# Seguridad: AWS Secrets Manager

**Problema:** Las connection strings y API keys no deben vivir en código ni en `appsettings.json` en producción.

**Solución del template:**

```
appsettings.json  ←  placeholder solamente
     │
     ▼ (si hay secreto configurado)
AWS Secrets Manager  →  AwsSecretsManagerDriver  →  connection string en memoria
     │
     ▼
DatabaseSkill usa la connection string resuelta
(nunca expuesta en logs ni variables de entorno)
```

**Flujo de autenticación:**

```
AWS SSO (IAM Identity Center)
  → aws sso login --profile PERFIL-GBM
  → Credenciales temporales (8 horas)
  → AwsCredentialsProvider (caché en memoria)
  → AmazonSecretsManagerClient autenticado
  → GetSecretValueAsync("/gbm/proyecto/sqlserver-credentials")
```

> **El secret nunca toca disco.** Solo existe en memoria durante la ejecución del escenario.

---

# Configuración AWS en `appsettings.json`

```json
{
  "AWSSettings": {
    "Region": "us-east-1",
    "Profile": "GBM-DEV",
    "Secrets": {
      "SobConnectionString": "/gbm/mi-proyecto/sqlserver-credentials"
    }
  },
  "DatabaseSettings": {
    "Provider": "SqlServer",
    "TimeoutSeconds": 30,
    "UseTransactionByDefault": false,
    "ConnectionString": ""
  }
}
```

**Prioridad de resolución de la connection string:**

1. Secreto de AWS Secrets Manager (si `SobConnectionString` tiene valor)
2. `DatabaseSettings:ConnectionString` directo (para local/dev sin AWS)
3. Si ninguno: `DatabaseSkill` **no se registra** (falla silenciosa, no rompe el resto)

---

<!-- _class: divider -->

# Parte 7
## Beneficios

---

# Beneficios para el Equipo de QA

<div class="columns">
<div>

**Productividad**
- Escribe escenarios en lenguaje natural, la IA resuelve la mecánica
- Onboarding de días en lugar de semanas
- Reutilización de steps entre proyectos (mismo framework)
- `bootstrap-template.ps1` genera un proyecto listo en < 2 minutos

**Calidad**
- StyleCop + FXCop aplica estándares automáticamente
- Código autodocumentado (XML docs obligatorios)
- Tests reproducibles en CI/CD (temperatura `0.0`)
- Cobertura de API, UI y BD en el mismo framework

</div>
<div>

**Mantenibilidad**
- Separación clara: el feature describe QUÉ, la IA decide CÓMO
- Cambiar de OpenAI a Azure OpenAI: 1 línea en `appsettings.json`
- Cambiar de SQL Server a PostgreSQL: 1 línea en `appsettings.json`
- Skills extensibles sin modificar el core

**Colaboración**
- Los features son legibles por Product Owners y stakeholders
- Living documentation: los escenarios son la especificación viva
- BDD fomenta conversaciones QA ↔ Desarrollo ↔ Negocio

</div>
</div>

---

# Beneficios para la Empresa

<div class="columns3">
<div>

**Estandarización**
<div class="card">
Un solo bootstrap genera cualquier proyecto de QA con la misma arquitectura, naming y convenciones.
</div>
<div class="card">
Auditabilidad garantizada: StyleCop + FXCop en cada build.
</div>

</div>
<div>

**Seguridad**
<div class="card">
Secretos nunca en código. AWS Secrets Manager como única fuente de verdad para credenciales.
</div>
<div class="card">
Credenciales temporales con AWS SSO (rotación automática).
</div>

</div>
<div>

**ROI**
<div class="card">
Reducción del tiempo de setup de nuevo proyecto QA: de semanas a horas.
</div>
<div class="card">
Reutilización de skills cross-equipo. Una mejora beneficia a todos los proyectos.
</div>

</div>
</div>

**Alineación con la industria:**
- Microsoft Semantic Kernel es el estándar empresarial para IA en .NET
- AWS SSO es el estándar de GBM para autenticación en nube
- BDD/Gherkin es la práctica recomendada por ISTQB para QA moderno

---

<!-- _class: divider -->

# Parte 8
## Casos de Uso en GBM

---

# Aplicabilidad en GBM

| Dominio | Tipo de prueba | Skills utilizadas |
|---|---|---|
| **Trading / Órdenes** | Validación de APIs de ejecución | `Api.GetRequest`, `Api.ValidateJsonSchema` |
| **Portal del Cliente** | Flujos de UI (login, portafolio, transferencias) | `Browser.NavigateTo`, `Browser.FillField` |
| **Reportes y Consultas** | Verificación de datos en BD | `Database.ExecuteQuery` |
| **Operaciones nocturnas** | Validación post-proceso batch | `Database.ExecuteScriptFile` |
| **Onboarding Digital** | Flujo completo E2E (UI + API + BD) | Todas las skills |
| **Conciliación** | Comparación DB vs respuesta API | `Api` + `Database` en mismo escenario |
| **CI/CD gates** | Smoke tests automáticos antes de deploy | `@smoke` tagged scenarios |

**Ejemplo de escenario E2E real:**

```gherkin
@e2e @trading
Scenario: Verificar que una orden de compra se registra correctamente
  When I instruct the AI to "post to https://api.gbm.com/orders with body {\"symbol\":\"AMXL\",\"qty\":100}"
  Then the AI action should succeed
  When I execute the SQL query "SELECT * FROM Orders WHERE Symbol='AMXL' AND Status='PENDING'" with parameters
    | Name   | Value |
    | Symbol | AMXL  |
  Then the database query should return at least 1 row
```

---

# El Bootstrap en Acción

**Para un nuevo proyecto sin BD:**
```powershell
.\bootstrap-template.ps1 -ProjectName "CuentasQA"
```

**Para un proyecto con integración AWS y BD:**
```powershell
.\bootstrap-template.ps1 `
    -ProjectName "TradingGatewayQA" `
    -UsePrivatePackages `
    -IncludeDatabase
```

**Resultado en < 2 minutos:**

```
src/TradingGatewayQA/
├── TradingGatewayQA.csproj    ✅ compilable
├── appsettings.json            ✅ con todos los placeholders
├── reqnroll.json               ✅ configurado
├── Drivers/                    ✅ AiContext, ConfigurationDriver, AWS*
├── Skills/                     ✅ Browser, Api, Database
├── StepDefinitions/            ✅ AI Orchestrator + Database steps
├── Hooks/                      ✅ lifecycle completo con DB
├── Features/                   ✅ Sample.feature con escenario DB
└── Tests/                      ✅ AwsConnectionTest smoke tests
```

> El proyecto **ya compila** con `dotnet build`. Solo hay que configurar `appsettings.json`.

---

<!-- _class: divider -->

# Parte 9
## Riesgos y Mitigaciones

---

# Riesgos Identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **LLM retorna JSON inválido** | Media | Alto | Validación estricta antes de `InvokeAsync` + mensaje diagnóstico con payload original |
| **Costo de API OpenAI/Azure** | Alta (si mal uso) | Medio | Temperatura `0.0`, tokens limitados a 500, los pasos directos NO usan LLM |
| **Expiración de sesión AWS SSO** | Alta (cada 8h) | Alto | `AwsSessionValidator` valida antes de ejecutar tests; documentación de renovación incluida |
| **Token VSTS expirado** | Media | Medio | El bootstrap inyecta desde ámbito de Usuario automáticamente |
| **Cambio de API del LLM** | Baja | Alto | Semantic Kernel abstrae el proveedor; migrar de OpenAI → AzureOpenAI es 1 línea de configuración |
| **Skill description ambigua** | Media | Medio | Convención de naming documentada; few-shot en el prompt |
| **Flaky tests por UI** | Media | Medio | Pasos directos para validaciones críticas; `BrowserSkill` como complemento, no como base |
| **Adopción sin capacitación** | Alta | Alto | Plan de onboarding + documentación normativa incluida en el repo |

---

# Riesgos: Profundidad Técnica

<div class="columns">
<div>

**Dependencia del LLM**
- El orquestador IA puede fallar si el modelo no está disponible
- **Mitigación:** Los pasos de base de datos son 100% deterministas y no dependen del LLM. Los casos críticos de negocio se prueban con `DatabaseStepDefinitions`, no con IA.

**Costo de tokens**
- 1 escenario IA ≈ ~300–500 tokens input + ~50 output
- gpt-4o: ~$0.005 por escenario
- Con 100 escenarios diarios en CI ≈ $0.50/día
- **Mitigación:** Taggear con `@ai` solo los escenarios que realmente necesitan IA

</div>
<div>

**Seguridad**
- Los secrets en `appsettings.json` son **solo placeholders**
- En CI/CD se inyectan por variables de entorno del pipeline
- AWS SSO garantiza credenciales temporales (TTL 8h)
- El template incluye `AwsConnectionTest` para validar la sesión antes de ejecutar

**Mantenimiento del prompt**
- Si se agregan nuevas skills, el few-shot del prompt debe actualizarse
- **Mitigación:** `available_skills` se inyecta dinámicamente desde los plugins registrados en el kernel; el prompt template está en disco, versionado en Git

</div>
</div>

---

<!-- _class: divider -->

# Parte 10
## Plan de Implementación

---

# Fases de Adopción Empresarial

| Fase | Duración | Actividad | Criterio de éxito |
|---|---|---|---|
| **Fase 0: Validación** | 1–2 semanas | Ejecutar el template con 1 proyecto piloto real | Proyecto compila, 5+ escenarios pasan en CI |
| **Fase 1: Piloto** | 2–4 semanas | 1 equipo QA adopta el template en un proyecto activo | 80% de los smoke tests automatizados |
| **Fase 2: Expansión** | 1–2 meses | 3–5 equipos adoptan el estándar | Feed privado accesible, documentación validada |
| **Fase 3: Estándar** | Ongoing | El bootstrap es el punto de partida oficial para nuevos proyectos QA | 0 nuevos proyectos QA sin el template |

**Prerequisitos para Fase 0:**

- [ ] API Key OpenAI o Azure OpenAI disponible
- [ ] AWS SSO configurado para el perfil del proyecto
- [ ] Token `VSTS_GITHUB_ACCESS_KEY` para el feed `gbmWallE`
- [ ] .NET 8 SDK en las máquinas de los QAs
- [ ] Acceso a AWS Secrets Manager (si se usará BD)

---

# Onboarding de un Nuevo QA

**Día 1 — Setup:**
```powershell
# 1. Configurar token del feed privado
[System.Environment]::SetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "token", "User")

# 2. Configurar AWS SSO
aws configure sso --profile GBM-DEV
aws sso login --profile GBM-DEV

# 3. Generar el proyecto
.\bootstrap-template.ps1 -ProjectName "MiProyectoQA" -UsePrivatePackages -IncludeDatabase

# 4. Configurar appsettings.json (reemplazar placeholders)
# 5. Ejecutar
dotnet test --filter Category=smoke
```

**Semana 1 — Escritura de escenarios:**
- Leer `prompts/00_Agent_Execution_Plan.md` (15 min)
- Leer `prompts/01_Stack_Setup.md` + `02_Architecture_Layout.md` (30 min)
- Escribir 5 escenarios propios usando los features de ejemplo

**El QA NO necesita entender Semantic Kernel para escribir pruebas efectivas.**

---

<!-- _class: divider -->

# Parte 11
## Mantenimiento y Evolución

---

# Modelo de Mantenimiento

<div class="columns">
<div>

**Responsabilidades del equipo dueño del template:**

- Actualizar versiones de paquetes (semestral o cuando hay CVE)
- Agregar nuevas skills al catálogo base
- Mantener la documentación normativa (`prompts/`)
- Publicar el `bootstrap-template.ps1` actualizado
- Resolver dependencias del feed privado `gbmWallE`

**Responsabilidades de cada equipo adoptante:**

- Configurar `appsettings.json` para su ambiente
- Agregar sus propios features y steps específicos del dominio
- Mantener sus secrets en AWS Secrets Manager
- Reportar problemas o mejoras al equipo dueño

</div>
<div>

**Versionado del template:**

```
bootstrap-template.ps1  ─────────────────────
                              │
                    v1.0  v1.1  v2.0
                       │     │     │
                    -Force para proyectos
                    que quieren migrar
                    a una versión nueva
```

**Evolución de skills:**

Agregar una skill nueva no rompe proyectos existentes. El bootstrap es **aditivo**: solo añade archivos, nunca modifica los existentes sin `-Force`.

</div>
</div>

---

# Hoja de Ruta Sugerida

| Versión | Mejora Propuesta | Impacto |
|---|---|---|
| **v1.1** | Skill de DynamoDB (`DynamoDbSkill`) | Pruebas de datos NoSQL |
| **v1.2** | Integración con Playwright como alternativa a Selenium en `BrowserSkill` | UI testing más robusto |
| **v1.3** | `SchemaInspectionSkill` — inspección de esquema DB via IA | Documentación automática de BD |
| **v2.0** | Modo "offline" del prompt (mock LLM) para CI sin API key | Pipeline 100% sin dependencias externas |
| **v2.1** | Skill de mensajería SQS/SNS para pruebas de eventos | Pruebas de arquitectura event-driven |
| **v2.2** | Reportes HTML con historial de ejecución por escenario | Visibilidad para stakeholders |

> Las skills `SchemaInspectionSkill` y `DatabaseSkill` ya tienen sus templates base en el repositorio (`08_SchemaInspection_Skill.md`).

---

<!-- _class: divider -->

# Parte 12
## Conclusión

---

# Resumen Ejecutivo

<div class="columns">
<div>

**Lo que entrega este prototipo:**

✅ Framework BDD completo con IA integrada
✅ Skills reutilizables: Browser, API, Database
✅ Integración nativa con AWS SSO + Secrets Manager
✅ Generación de proyecto en 1 comando
✅ Estándares de código aplicados automáticamente
✅ Documentación normativa completa (14 docs)
✅ Compilable y ejecutable desde el primer día
✅ Diseñado para CI/CD (determinismo, temperatura 0.0)

</div>
<div>

**Lo que resuelve:**

🔴 QA manual que no escala → **QA automatizado con IA**
🔴 Sin estándar por equipo → **Un template, todos los proyectos**
🔴 Secretos en código → **AWS Secrets Manager**
🔴 Onboarding lento → **Setup en 1 comando**
🔴 Escenarios técnicos → **Gherkin de negocio**
🔴 Cobertura inconsistente → **API + UI + DB en un mismo framework**

</div>
</div>

---

# Propuesta Concreta

> **Adoptar `AiTemplateAutomation` como template estándar de QA automation en GBM,**
> comenzando con un piloto de 4 semanas en 1 proyecto activo.

**Lo que se necesita para arrancar:**

| Recurso | Detalle |
|---|---|
| **Infraestructura** | API Key Azure OpenAI (ya disponible en GBM) · AWS SSO (ya configurado) |
| **Equipo** | 1 QA senior para el piloto + soporte del equipo dueño del template |
| **Tiempo** | Semana 1: setup y validación · Semanas 2–4: escenarios reales |
| **Inversión** | ~$15–30 USD/mes en tokens LLM para el piloto (100–200 escenarios/día) |

**Resultado esperado del piloto:**
- 50+ escenarios automatizados del proyecto piloto
- 80% de los smoke tests ejecutándose en CI/CD
- Documentación de lecciones aprendidas para la expansión

---

<!-- _class: title -->

# ¿Preguntas?

---

**Repositorio:** `c:\Repos\AiTemplateAutomation`
**Bootstrap:** `.\bootstrap-template.ps1 -ProjectName "MiProyecto"`
**Documentación:** `prompts/README.md`

---

*GBM Grupo Bursátil Mexicano · QA Automation con IA · Marzo 2026*
