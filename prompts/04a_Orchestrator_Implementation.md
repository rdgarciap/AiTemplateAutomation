# 04a — Orchestrator Implementation

**Tipo:** Implementacion  
**Depende de:** `04_Prompt_Engineering.md`

## DTO base

```csharp
using Newtonsoft.Json;

namespace {{PROJECT_NAME}}.StepDefinitions;

public record OrchestratorCommand(
    [property: JsonProperty("skill")] string Skill,
    [property: JsonProperty("function")] string Function,
    [property: JsonProperty("args")] Dictionary<string, string> Args
);
```

## Step definition base

```csharp
using {{PROJECT_NAME}}.Drivers;
using Microsoft.SemanticKernel;
using Newtonsoft.Json;
using NUnit.Framework;
using Reqnroll;

namespace {{PROJECT_NAME}}.StepDefinitions;

[Binding]
public class AiOrchestratorSteps
{
    private readonly AiContext _aiContext;
    private readonly Kernel _kernel;

    public AiOrchestratorSteps(AiContext aiContext, Kernel kernel)
    {
        _aiContext = aiContext;
        _kernel = kernel;
    }

    [When(@"I instruct the AI to ""(.*)""")]
    public async Task WhenIInstructTheAiToAsync(string instruction)
    {
        var promptPath = Path.Combine(AppContext.BaseDirectory, "Prompts", "orchestrator.skprompt.txt");
        var promptTemplate = await File.ReadAllTextAsync(promptPath);
        var availableSkills = string.Join(", ", _kernel.Plugins.Select(plugin => plugin.Name));

        var arguments = new KernelArguments
        {
            ["instruction"] = instruction,
            ["available_skills"] = availableSkills
        };

        var result = await _kernel.InvokePromptAsync(promptTemplate, arguments);
        var rawJson = result.ToString();
        _aiContext.LastRawResponse = rawJson;

        var command = JsonConvert.DeserializeObject<OrchestratorCommand>(rawJson)
            ?? throw new InvalidOperationException($"LLM returned invalid JSON: {rawJson}");

        var kernelArgs = new KernelArguments();
        foreach (var pair in command.Args)
            kernelArgs[pair.Key] = pair.Value;

        var skillResult = await _kernel.InvokeAsync(command.Skill, command.Function, kernelArgs);
        _aiContext.LastSkillResult = skillResult.ToString();
    }

    [Then(@"the AI action should succeed")]
    public void ThenTheAiActionShouldSucceed()
    {
        Assert.That(_aiContext.LastSkillResult, Is.Not.Null);
        Assert.That(_aiContext.LastSkillResult!.ToString(), Does.Not.Contain("error").IgnoreCase);
    }
}
```

## Template base

```text
You are an AI orchestrator for a test automation framework.
Your ONLY job is to select the correct skill and function.
Available skills: {{$available_skills}}

RULES:
- Respond ONLY with a single JSON object.
- JSON format: {"skill":"PluginName","function":"FunctionName","args":{"param":"value"}}
- If args are empty use: "args":{}
- Use exact plugin and function names.

Instruction: "{{$instruction}}"
Output:
```


