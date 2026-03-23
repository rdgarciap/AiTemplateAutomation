# 03a — Skills Implementation

**Tipo:** Implementacion  
**Depende de:** `03_Skills_Extensibility.md`

Este archivo contiene las implementaciones base para `BrowserSkill` y `ApiSkill`. El código canónico vive en los templates `templates/bootstrap/Skills/BrowserSkill.cs.template` y `templates/bootstrap/Skills/ApiSkill.cs.template`; este documento los describe para guiar al agente.

## `BrowserSkill.cs`

### Funciones expuestas

| Kernel function | Parámetros | Cuándo usarla |
|---|---|---|
| `NavigateTo` | `url: string` | Navegar el browser a una URL completa. |
| `ClickElement` | `selector: string` | Hacer clic en un elemento por selector o texto visible. |
| `FillField` | `selector: string`, `value: string` | Escribir un valor en un campo de entrada. |
| `GetElementText` | `selector: string` | Leer el texto de un elemento de la página. |

### Implementación

```csharp
using System.ComponentModel;
using {{PROJECT_NAME}}.Drivers;
using Microsoft.SemanticKernel;

namespace {{PROJECT_NAME}}.Skills;

public class BrowserSkill
{
    private readonly AiContext _aiContext;

    public BrowserSkill(AiContext aiContext)
    {
        _aiContext = aiContext;
    }

    [KernelFunction("NavigateTo")]
    [Description("Navigates the browser to the specified URL.")]
    public string NavigateTo([Description("The full URL to navigate to.")] string url)
    {
        var result = $"{{\"action\":\"NavigateTo\",\"url\":\"{url}\",\"status\":\"success\"}}";
        _aiContext.LastSkillResult = result;
        return result;
    }

    [KernelFunction("ClickElement")]
    [Description("Clicks on an element identified by selector or visible text.")]
    public string ClickElement([Description("Selector or visible text.")] string selector)
    {
        var result = $"{{\"action\":\"ClickElement\",\"selector\":\"{selector}\",\"status\":\"success\"}}";
        _aiContext.LastSkillResult = result;
        return result;
    }

    [KernelFunction("FillField")]
    [Description("Fills an input field identified by selector.")]
    public string FillField(
        [Description("Selector or logical field name.")] string selector,
        [Description("Value to write.")] string value)
    {
        var result = $"{{\"action\":\"FillField\",\"selector\":\"{selector}\",\"value\":\"{value}\",\"status\":\"success\"}}";
        _aiContext.LastSkillResult = result;
        return result;
    }

    [KernelFunction("GetElementText")]
    [Description("Gets text from an element identified by selector.")]
    public string GetElementText([Description("Selector or logical element name.")] string selector)
    {
        var result = $"{{\"action\":\"GetElementText\",\"selector\":\"{selector}\",\"text\":\"[element text]\",\"status\":\"success\"}}";
        _aiContext.LastSkillResult = result;
        return result;
    }
}
```

### Reglas de extensión

- `FillField` y `GetElementText` son stubs. Al integrar un browser driver real (Playwright, Selenium), reemplazar el cuerpo pero **no cambiar** el nombre de `KernelFunction` ni la firma de parámetros sin antes actualizar `03_Skills_Extensibility.md`.
- El resultado siempre debe ser JSON serializable y almacenarse en `AiContext.LastSkillResult`.

---

## `ApiSkill.cs`

### Funciones expuestas

| Kernel function | Parámetros | Cuándo usarla |
|---|---|---|
| `GetRequest` | `url: string` | Ejecutar un HTTP GET y almacenar el response body. |
| `PostRequest` | `url: string`, `body: string` | Ejecutar un HTTP POST con body JSON. |
| `ValidateJsonSchema` | `requiredFields: string` | Validar que el último response contiene campos requeridos. No hace un HTTP call; opera sobre `LastSkillResult`. |

### Implementación

```csharp
using System.ComponentModel;
using System.Text;
using {{PROJECT_NAME}}.Drivers;
using Microsoft.SemanticKernel;
using Newtonsoft.Json.Linq;

namespace {{PROJECT_NAME}}.Skills;

public class ApiSkill
{
    private readonly AiContext _aiContext;
    private static readonly HttpClient HttpClient = new();

    public ApiSkill(AiContext aiContext)
    {
        _aiContext = aiContext;
    }

    [KernelFunction("GetRequest")]
    [Description("Executes an HTTP GET request and stores the response body.")]
    public async Task<string> GetRequestAsync([Description("The target URL.")] string url)
    {
        var response = await HttpClient.GetStringAsync(url);
        _aiContext.LastSkillResult = response;
        return response;
    }

    [KernelFunction("PostRequest")]
    [Description("Executes an HTTP POST request with a JSON body.")]
    public async Task<string> PostRequestAsync(
        [Description("The target URL.")] string url,
        [Description("JSON body.")] string body)
    {
        var content = new StringContent(body, Encoding.UTF8, "application/json");
        var response = await HttpClient.PostAsync(url, content);
        var result = await response.Content.ReadAsStringAsync();
        _aiContext.LastSkillResult = result;
        return result;
    }

    [KernelFunction("ValidateJsonSchema")]
    [Description("Validates that the last API response contains all required fields.")]
    public string ValidateJsonSchema([Description("Comma-separated required fields.")] string requiredFields)
    {
        _aiContext.ValidationErrors.Clear();
        var responseJson = _aiContext.LastSkillResult?.ToString();
        if (string.IsNullOrWhiteSpace(responseJson))
        {
            _aiContext.ValidationErrors.Add("No API response available to validate.");
            return "Validation failed: no response.";
        }

        var token = JToken.Parse(responseJson);
        var responseObject = token is JArray arr ? arr.FirstOrDefault() as JObject : token as JObject;
        if (responseObject is null)
        {
            _aiContext.ValidationErrors.Add("Response is not a JSON object or array of objects.");
            return "Validation failed: invalid JSON shape.";
        }

        foreach (var field in requiredFields.Split(',').Select(item => item.Trim()).Where(item => item.Length > 0))
        {
            if (responseObject[field] is null)
                _aiContext.ValidationErrors.Add($"Missing required field: {field}");
        }

        return _aiContext.ValidationErrors.Count == 0 ? "Validation succeeded." : "Validation failed.";
    }
}
```

### Reglas de extensión

- `ValidateJsonSchema` opera sobre `AiContext.LastSkillResult`, no realiza llamadas HTTP.
- Escribe los errores en `AiContext.ValidationErrors` para que los steps de aserción puedan inspeccionarlos.
- `HttpClient` es estático compartido por instancia de clase. Si se requiere configuración por escenario (cabeceras de auth, timeout), inyectar `HttpClient` por constructor en lugar de usar el campo estático.

---

## Nota

Cuando se reemplacen stubs por integraciones reales, el contrato de nombres y salidas no debe cambiar sin antes actualizar `03_Skills_Extensibility.md`.


