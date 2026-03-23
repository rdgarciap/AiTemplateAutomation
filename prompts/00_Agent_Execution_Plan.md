# 00 — Plan de Ejecución del Agente

**Tipo:** Normativo  
**Rol:** Orquestador del paquete documental

Este archivo define el recorrido oficial para construir el proyecto desde cero usando los prompts de este directorio.

## Objetivo

Generar un template de automatizacion QA con IA que sea:

- compilable en .NET 8
- ejecutable con Reqnroll + NUnit
- extensible por skills
- deterministicamente configurable
- compatible con escenarios directos y con orquestacion AI

## Entradas Mínimas

Antes de empezar, el agente debe contar con:

1. [AgentRol.md](AgentRol.md) cargado como contexto de estilo y stack.
2. [NuGet.Config](NuGet.Config) ya presente en la raiz.
3. `.gitignore` ya presente en la raiz.
4. acceso al feed privado si se utilizara `Gbm.Automation.Core`.

## Salida Objetivo del Repositorio

```text
(raiz)/
├── .github/
├── build/
├── prompts/
├── src/
│   └── <ProjectName>/
│       ├── Drivers/
│       ├── Features/
│       ├── Hooks/
│       ├── Prompts/
│       ├── Scripts/
│       ├── Skills/
│       ├── StepDefinitions/
│       ├── appsettings.json
│       ├── <ProjectName>.csproj
│       └── reqnroll.json
├── <ProjectName>.sln
└── NuGet.Config
```

## Secuencia Oficial

### Fase 1 — Contrato Técnico Base

**Leer:** [prompts/01_Stack_Setup.md](prompts/01_Stack_Setup.md)

**Definir:**

- solucion
- proyecto `.csproj`
- `appsettings.json`
- `reqnroll.json`

**Criterio de cierre:** existe un proyecto de pruebas compilable con configuracion minima completa.

### Fase 2 — Arquitectura Core

**Leer:** [prompts/02_Architecture_Layout.md](prompts/02_Architecture_Layout.md)  
**Apoyarse en:** [prompts/02a_Core_Implementation.md](prompts/02a_Core_Implementation.md)

**Definir:**

- `AiContext`
- `ConfigurationDriver`
- `TestLifecycleHooks`

**Criterio de cierre:** lifecycle por escenario definido, DI consistente y registro del kernel controlado.

### Fase 3 — Skills Base

**Leer:** [prompts/03_Skills_Extensibility.md](prompts/03_Skills_Extensibility.md)  
**Apoyarse en:** [prompts/03a_Skills_Implementation.md](prompts/03a_Skills_Implementation.md)

**Definir:**

- `BrowserSkill`
- `ApiSkill`
- convenciones para nuevas skills

**Criterio de cierre:** cada skill expone funciones con naming consistente y contratos de salida claros.

### Fase 4 — Orquestador AI

**Leer:** [prompts/04_Prompt_Engineering.md](prompts/04_Prompt_Engineering.md)  
**Apoyarse en:** [prompts/04a_Orchestrator_Implementation.md](prompts/04a_Orchestrator_Implementation.md)

**Definir:**

- DTO del comando del orquestador
- step definitions del flujo AI
- template `orchestrator.skprompt.txt`

**Criterio de cierre:** el LLM responde con JSON valido, el comando se valida y la invocacion al kernel queda controlada.

### Fase 5 — Integracion AWS (opcional)

> Ejecutar esta fase solo si el proyecto consume AWS (Secrets Manager, DynamoDB, etc.).
> Es **prerequisito** de la Fase 6 si la conexion a BD se resuelve via AWS Secrets Manager.

**Leer:** [prompts/05_AWS_SSO_Setup.md](prompts/05_AWS_SSO_Setup.md)
**Apoyarse en:** [prompts/06_AWS_Integration_Template.md](prompts/06_AWS_Integration_Template.md)

**Definir:**

- configuracion de AWS CLI y perfil SSO
- `AwsCredentialsProvider`
- `AwsSessionValidator`
- `AwsClientFactory` y `SecretsManagerWrapper` (si se usan paquetes privados)

**Criterio de cierre:** `AwsSessionValidator.ValidateSessionAsync()` retorna `true` con el perfil del proyecto.

### Fase 6 — Dominio de base de datos (opcional)

**Leer:** [prompts/07_Database_Skill.md](prompts/07_Database_Skill.md)
**Apoyarse en:** `07a`, `07b`, `07c`, `07d`, `07e`

**Definir:**

- setup de DB y secretos (directo o via AWS Secrets Manager)
- `DatabaseSkill`
- `DatabaseStepDefinitions`
- patrones de escenarios con BD

**Criterio de cierre:** existen pasos directos deterministas para DB y un contrato explicito para uso excepcional del LLM.

### Fase 7 — Feature de ejemplo

**Definir:**

- un feature minimo que demuestre browser, API y database

**Criterio de cierre:** el feature demuestra el uso del framework sin introducir ambiguedades de arquitectura.

## Reglas Globales

1. Nunca dupliques un contrato ya definido en otro prompt. Referencialo.
2. Evita estado estatico mutable en clases de escenario.
3. Los secretos reales nunca deben escribirse en archivos versionados.
4. Los pasos de base de datos son directos por defecto; el LLM solo se usa para probar routing del agente.
5. Todo archivo leido en runtime debe quedar explicitamente marcado para copiarse al output.

## Definición de Terminado

La ejecucion esta completa cuando:

1. la solucion compila
2. los documentos normativos no se contradicen
3. los archivos de implementacion respetan el contrato
4. los documentos de referencia no redefinen comportamiento


