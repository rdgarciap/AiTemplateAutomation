# 02 — Arquitectura y Layout

**Tipo:** Normativo  
**Rol:** Contrato de arquitectura del template

Este archivo define el comportamiento esperado del core del framework. El codigo de implementacion puede variar, pero no debe romper estas decisiones.

## Estructura de Carpetas

```text
src/<ProjectName>/
├── Drivers/
├── Features/
├── Hooks/
├── Prompts/
├── Scripts/
├── Skills/
└── StepDefinitions/
```

## Componentes Core

| Componente | Responsabilidad |
|---|---|
| `AiContext` | Estado compartido por escenario. |
| `ConfigurationDriver` | Lectura tipada de configuracion desde `appsettings.json` y variables de entorno. |
| `TestLifecycleHooks` | Construccion del kernel, registro de skills y limpieza por escenario. |
| `Kernel` | Punto de entrada para invocar plugins y prompts. |

## Política de Ciclo de Vida

1. `AiContext` es **por escenario**.
2. `Kernel` es **por escenario**.
3. Las skills son **por escenario**.
4. `ConfigurationDriver` puede ser por escenario para mantener aislamiento y simplicidad.
5. No se permite estado estatico mutable en clases de escenario.

## Flujo por Escenario

1. Reqnroll carga el escenario.
2. `BeforeScenario` crea `AiContext`.
3. `BeforeScenario` carga configuracion y construye el `Kernel`.
4. Se instancian y registran las skills habilitadas.
5. Los steps ejecutan acciones directas o via AI.
6. `AfterScenario` libera recursos externos y deja el estado consistente.

## Contrato de `AiContext`

Propiedades minimas esperadas:

- `LastRawResponse`
- `LastSkillResult`
- `ValidationErrors`
- `SharedData`

### Reglas de uso

1. `LastRawResponse` almacena la respuesta cruda del LLM para diagnostico.
2. `LastSkillResult` almacena el ultimo resultado funcional util para aserciones.
3. `ValidationErrors` solo contiene errores de validacion, no excepciones tecnicas crudas.
4. `SharedData` se usa para intercambio temporal entre steps, nunca como cache global.

## Contrato de `ConfigurationDriver`

Debe exponer, como minimo:

- modo AI
- temperatura
- tokens maximos
- credenciales y modelo OpenAI
- credenciales y deployment Azure OpenAI
- cadena de conexion
- timeout de DB
- proveedor de DB
- bandera `UseTransactionByDefault`

### Reglas de carga

1. Leer primero `appsettings.json`.
2. Aplicar luego `AddEnvironmentVariables()` para permitir override.
3. No asumir que `DatabaseSettings` siempre tendra credenciales reales.
4. El constructor no debe hacer IO externo adicional ni validaciones destructivas.

## Contrato de `TestLifecycleHooks`

`BeforeScenario` debe:

1. registrar `AiContext`
2. registrar `ConfigurationDriver`
3. construir el `Kernel`
4. registrar `BrowserSkill` y `ApiSkill`
5. registrar `DatabaseSkill` solo si la conexion es valida y no placeholder

### Reglas de DB

1. Si no existe una cadena efectiva, ya sea directa en `DatabaseSettings.ConnectionString` o resuelta desde `AWSSettings:Secrets:SobConnectionString`, no registrar `DatabaseSkill`.
2. Respetar `DatabaseSettings.Provider` al construir `DbClientBuilder`.
3. Si `UseTransactionByDefault = true`, aplicar transacciones por defecto al builder.

## Reglas de Limpieza

`AfterScenario` debe dejar explicitamente definido que recursos se liberan:

- browser o driver UI si existe
- conexiones o transacciones abiertas si el cliente lo requiere
- datos temporales alojados fuera de `AiContext`

## Limites de Arquitectura

1. Los steps de base de datos no pasan por el LLM salvo pruebas explicitas de routing.
2. El prompt del orquestador no decide si la configuracion es valida; esa validacion pertenece al bootstrap.
3. Los documentos de referencia no pueden redefinir el lifecycle ni la forma de registrar dependencias.

## Implementación Asociada

Para materializar este contrato, usar [prompts/02a_Core_Implementation.md](prompts/02a_Core_Implementation.md).


