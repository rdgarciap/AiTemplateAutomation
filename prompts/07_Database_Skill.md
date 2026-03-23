# 07 — Database Skill

**Tipo:** Hub  
**Rol:** Punto de entrada del dominio de base de datos

Este archivo organiza la documentacion de base de datos y define la decision principal del dominio: cuando usar pasos directos y cuando usar AI.

## Decision principal

| Enfoque | Quien define el SQL | Uso recomendado |
|---|---|---|
| Pasos directos | El autor del escenario | Validacion de datos, setup, teardown y consultas deterministas |
| Orquestador AI | El LLM | Solo pruebas de routing o comportamiento del agente |

## Regla del dominio

Las validaciones funcionales de base de datos deben hacerse con pasos directos. El uso del LLM para construir o inferir SQL es excepcional.

## Mapa de documentos

| Archivo | Tipo | Uso |
|---|---|---|
| `07a_Database_Setup.md` | Referencia | Setup de feed, provider, secretos y connection string |
| `07b_Database_Steps_Reference.md` | Referencia | Catalogo de pasos y contratos de salida |
| `07c_Database_Scenario_Patterns.md` | Referencia | Patrones de escenarios y tagging |
| `07d_Database_CICD_Troubleshooting.md` | Referencia | Operacion en CI/CD y diagnostico |
| `07e_Database_Implementation.md` | Implementacion | `DatabaseSkill` y `DatabaseStepDefinitions` |

## Limites del modulo

1. No expone SQL generado por el LLM como mecanismo principal de test.
2. No redefine las reglas de arquitectura ni de configuracion base.
3. Debe respetar `DatabaseSettings` definido en `01_Stack_Setup.md`.



