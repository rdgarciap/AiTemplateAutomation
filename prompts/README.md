# Prompts — Mapa de Lectura

Este directorio contiene la especificacion documental del template `<ProjectName>` (por defecto `DemoFinancialServicesQA`).

## Tipos de documento

| Tipo | Uso | Regla de prioridad |
|---|---|---|
| **Normativo** | Define contratos, reglas y decisiones arquitectonicas. | Si hay conflicto, este documento manda. |
| **Implementacion** | Muestra como materializar el contrato en archivos concretos. | Debe respetar siempre al documento normativo asociado. |
| **Referencia** | Catalogos, patrones, troubleshooting y ejemplos operativos. | No redefine contratos. |
| **Indice / Hub** | Organiza el recorrido de lectura. | No introduce nuevas reglas tecnicas. |

## Orden recomendado de lectura

1. `00_Agent_Execution_Plan.md`
2. `01_Stack_Setup.md`
3. `02_Architecture_Layout.md`
4. `03_Skills_Extensibility.md`
5. `04_Prompt_Engineering.md`
6. Si el proyecto usa **AWS** (Secrets Manager, DynamoDB, etc.) — prerequisito para la BD via secretos:
   - **`05_AWS_SSO_Setup.md`** — Configuracion de AWS SSO
   - **`06_AWS_Integration_Template.md`** — Template de implementacion AWS
7. Si el proyecto usa **base de datos**:
   - `07_Database_Skill.md` — Hub del dominio de BD
   - `07a_Database_Setup.md` — Setup operativo (feed privado, connection string, AWS)
   - `07b_Database_Steps_Reference.md` — Catalogo de pasos Gherkin
   - `07c_Database_Scenario_Patterns.md` — Patrones y anti-patrones
   - `07d_Database_CICD_Troubleshooting.md` — CI/CD y troubleshooting
   - `07e_Database_Implementation.md` — Implementacion de skill y steps

## Mapa de archivos

| Archivo | Tipo | Proposito |
|---|---|---|
| `00_Agent_Execution_Plan.md` | Indice / Normativo | Orden de ensamblaje, salidas esperadas y criterios de cierre. |
| `01_Stack_Setup.md` | Normativo | Contrato tecnico base: stack, paquetes, configuracion y archivos minimos. |
| `02_Architecture_Layout.md` | Normativo | Contrato de arquitectura, ciclo de vida, DI y responsabilidades core. |
| `02a_Core_Implementation.md` | Implementacion | Guia de implementacion de `AiContext`, `ConfigurationDriver` y `TestLifecycleHooks`. |
| `03_Skills_Extensibility.md` | Normativo | Estandar de diseno de skills y reglas de registro en el kernel. |
| `03a_Skills_Implementation.md` | Implementacion | Implementacion de `BrowserSkill` y `ApiSkill` con todas sus funciones. |
| `04_Prompt_Engineering.md` | Normativo | Contrato del orquestador: JSON, validacion, few-shot y tolerancia a errores. |
| `04a_Orchestrator_Implementation.md` | Implementacion | DTOs, steps y template base del prompt runtime. |
| `05_AWS_SSO_Setup.md` | Referencia | Configuracion de AWS SSO. Prerequisito para AWS Secrets Manager. |
| `06_AWS_Integration_Template.md` | Normativo / Template | Template oficial para integracion con AWS usando Gbm.Automation.Core. |
| `07_Database_Skill.md` | Hub | Punto de entrada del dominio de base de datos. |
| `07a_Database_Setup.md` | Referencia | Setup de feed privado, cadena de conexion, proveedores y secretos. |
| `07b_Database_Steps_Reference.md` | Referencia | Catalogo funcional de pasos Gherkin y contratos de salida. |
| `07c_Database_Scenario_Patterns.md` | Referencia | Patrones de escenarios, tags y anti-patrones. |
| `07d_Database_CICD_Troubleshooting.md` | Referencia | Troubleshooting operativo y CI/CD para escenarios con BD. |
| `07e_Database_Implementation.md` | Implementacion | Implementacion sugerida de `DatabaseSkill` y `DatabaseStepDefinitions`. |

## Reglas de mantenimiento

1. No dupliques contratos entre archivos. Referencia al documento normativo correspondiente.
2. Cuando cambies una firma, actualiza primero el contrato y luego la implementacion.
3. Los ejemplos operativos no deben contradecir naming, JSONs ni reglas de lifecycle.
4. Si un documento deja de ser fuente de verdad, indicalo explicitamente.

## Regla de resolucion de conflictos

Si dos archivos se contradicen, resuelve asi:

1. Gana el documento **Normativo**.
2. Luego gana el documento de **Implementacion** asociado.
3. La **Referencia** solo ilustra y no redefine contratos.


