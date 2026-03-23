#Requires -Version 5.1
<#
.SYNOPSIS
    Genera la salida base de <ProjectName> a partir del paquete documental.

.DESCRIPTION
    Crea la solucion, el proyecto .NET, la estructura de carpetas y los archivos minimos
    para el template (por defecto DemoFinancialServicesQA). Opcionalmente ejecuta restore y build.

    El script esta pensado como entrypoint unico para agentes o desarrolladores que
    necesiten materializar el template sin recorrer manualmente todos los prompts.

.PARAMETER ProjectName
    Nombre del proyecto y de la solucion a generar. Por defecto: DemoFinancialServicesQA.

.PARAMETER Force
    Sobrescribe archivos generados si ya existen.

.PARAMETER SkipRestore
    Omite dotnet restore y dotnet build al finalizar.

.PARAMETER UsePrivatePackages
    Incluye Gbm.Automation.Core y el scaffolding de base de datos que depende del feed privado.

.PARAMETER IncludeDatabase
    Genera DatabaseSkill y DatabaseStepDefinitions. Requiere -UsePrivatePackages.
#>

[CmdletBinding()]
param(
    [string]$ProjectName = "DemoFinancialServicesQA",
    [switch]$Force,
    [switch]$SkipRestore,
    [switch]$UsePrivatePackages,
    [switch]$IncludeDatabase
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($IncludeDatabase -and -not $UsePrivatePackages) {
    throw "-IncludeDatabase requiere -UsePrivatePackages porque DatabaseSkill depende de Gbm.Automation.Core."
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatesRoot = Join-Path $repoRoot "templates\bootstrap"
$solutionPath = Join-Path $repoRoot "$ProjectName.sln"
$srcRoot = Join-Path $repoRoot "src"
$projectRoot = Join-Path $srcRoot $ProjectName

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor Cyan
}

function New-DirectoryIfMissing {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Write-FileSafely {
    param(
        [string]$Path,
        [string]$Content,
        [switch]$AllowOverwrite
    )

    if ([System.IO.Path]::GetExtension($Path) -eq ".cs") {
        $fileName = [System.IO.Path]::GetFileName($Path)
        $copyrightHeader = @"
// <copyright file="$fileName" company="GBM">
// GBM GRUPO BURSÁTIL MEXICANO, S.A DE C.V., CASA DE BOLSA
// </copyright>

"@

        if (-not $Content.StartsWith("// <copyright file=")) {
            $Content = $copyrightHeader + $Content.TrimStart("`r", "`n")
        }
    }

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-DirectoryIfMissing $parent
    }

    if ((Test-Path $Path) -and -not $AllowOverwrite) {
        Write-Host "SKIP  $Path" -ForegroundColor DarkYellow
        return
    }

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "WRITE $Path" -ForegroundColor Green
}

function Get-TemplateContent {
    param(
        [string]$RelativePath,
        [hashtable]$Tokens
    )

    $templatePath = Join-Path $templatesRoot $RelativePath
    if (-not (Test-Path $templatePath)) {
        throw "No se encontro la plantilla: $templatePath"
    }

    $content = Get-Content -Path $templatePath -Raw -Encoding UTF8

    foreach ($key in $Tokens.Keys) {
        $placeholder = "{{" + $key + "}}"
        $content = $content.Replace($placeholder, [string]$Tokens[$key])
    }

    return $content
}

function Get-TokenFromUserScope {
    return [System.Environment]::GetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "User")
}

Write-Section "Preparando estructura"

New-DirectoryIfMissing $srcRoot
New-DirectoryIfMissing $projectRoot
New-DirectoryIfMissing (Join-Path $projectRoot "Drivers")
New-DirectoryIfMissing (Join-Path $projectRoot "Drivers\Aws")
New-DirectoryIfMissing (Join-Path $projectRoot "Hooks")
New-DirectoryIfMissing (Join-Path $projectRoot "Properties")
New-DirectoryIfMissing (Join-Path $projectRoot "Skills")
New-DirectoryIfMissing (Join-Path $projectRoot "StepDefinitions")
New-DirectoryIfMissing (Join-Path $projectRoot "Models")
New-DirectoryIfMissing (Join-Path $projectRoot "Features")
New-DirectoryIfMissing (Join-Path $projectRoot "Prompts")
New-DirectoryIfMissing (Join-Path $projectRoot "Scripts")
New-DirectoryIfMissing (Join-Path $projectRoot "Tests")

$tokens = @{
    PROJECT_NAME = $ProjectName
}

$packageReferences = @(
    '    <PackageReference Include="Microsoft.SemanticKernel" Version="1.30.0" />',
    '    <PackageReference Include="Reqnroll" Version="2.4.0" />',
    '    <PackageReference Include="Reqnroll.NUnit" Version="2.4.0" />',
    '    <PackageReference Include="NUnit" Version="4.2.2" />',
    '    <PackageReference Include="NUnit3TestAdapter" Version="4.6.0">',
    '      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>',
    '      <PrivateAssets>all</PrivateAssets>',
    '    </PackageReference>',
    '    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.12.0" />',
    '    <PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="10.0.1" />',
    '    <PackageReference Include="Microsoft.Extensions.Configuration.EnvironmentVariables" Version="9.0.0" />',
    '    <PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="8.0.1" />',
    '    <PackageReference Include="AWSSDK.Core" Version="4.0.3.19" />',
    '    <PackageReference Include="AWSSDK.SSO" Version="4.0.2.17" />',
    '    <PackageReference Include="AWSSDK.SSOOIDC" Version="4.0.3.7" />',
    '    <PackageReference Include="AWSSDK.SecurityToken" Version="4.0.5.13" />',
    '    <PackageReference Include="AWSSDK.SecretsManager" Version="4.0.2.17" />',
    '    <PackageReference Include="Newtonsoft.Json" Version="13.0.4" />'
)

if ($UsePrivatePackages) {
    $packageReferences += @(
    '    <PackageReference Include="Gbm.Automation.Core" Version="1.7.7" />',
    '    <PackageReference Include="Dapper" Version="2.1.66" />'
    )
}

$packageReferencesXml = $packageReferences -join [Environment]::NewLine

$csprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">

    <PropertyGroup>
        <TargetFramework>net8.0</TargetFramework>
        <IsTestProject>true</IsTestProject>
        <Nullable>enable</Nullable>
        <ImplicitUsings>enable</ImplicitUsings>
        <NoWarn>CS1591</NoWarn>
    </PropertyGroup>

    <ItemGroup>
$packageReferencesXml
    </ItemGroup>

    <ItemGroup>
        <None Update="appsettings.json">
            <CopyToOutputDirectory>Always</CopyToOutputDirectory>
        </None>
        <None Update="reqnroll.json">
            <CopyToOutputDirectory>Always</CopyToOutputDirectory>
        </None>
        <None Update="Prompts\*.txt">
            <CopyToOutputDirectory>Always</CopyToOutputDirectory>
        </None>
        <None Update="Scripts\*.sql">
            <CopyToOutputDirectory>Always</CopyToOutputDirectory>
        </None>
    </ItemGroup>

</Project>
"@

Write-Section "Escribiendo archivos base"

Write-FileSafely -Path (Join-Path $projectRoot "$ProjectName.csproj") -Content $csprojContent -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "appsettings.json") -Content (Get-TemplateContent -RelativePath "appsettings.json.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "reqnroll.json") -Content (Get-TemplateContent -RelativePath "reqnroll.json.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Drivers\AiContext.cs") -Content (Get-TemplateContent -RelativePath "Drivers\AiContext.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Drivers\AwsCredentialsProvider.cs") -Content (Get-TemplateContent -RelativePath "Drivers\AwsCredentialsProvider.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Drivers\AwsSecretsManagerDriver.cs") -Content (Get-TemplateContent -RelativePath "Drivers\AwsSecretsManagerDriver.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Drivers\AwsSessionValidator.cs") -Content (Get-TemplateContent -RelativePath "Drivers\AwsSessionValidator.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Drivers\ConfigurationDriver.cs") -Content (Get-TemplateContent -RelativePath "Drivers\ConfigurationDriver.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Drivers\DataConnectionSettings.cs") -Content (Get-TemplateContent -RelativePath "Drivers\DataConnectionSettings.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Properties\launchSettings.json") -Content (Get-TemplateContent -RelativePath "Properties\launchSettings.json.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Skills\BrowserSkill.cs") -Content (Get-TemplateContent -RelativePath "Skills\BrowserSkill.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Skills\ApiSkill.cs") -Content (Get-TemplateContent -RelativePath "Skills\ApiSkill.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Models\DatabaseQueryResultDto.cs") -Content (Get-TemplateContent -RelativePath "Models\DatabaseQueryResultDto.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "StepDefinitions\OrchestratorCommand.cs") -Content (Get-TemplateContent -RelativePath "StepDefinitions\OrchestratorCommand.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "StepDefinitions\AiOrchestratorSteps.cs") -Content (Get-TemplateContent -RelativePath "StepDefinitions\AiOrchestratorSteps.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
Write-FileSafely -Path (Join-Path $projectRoot "Prompts\orchestrator.skprompt.txt") -Content (Get-TemplateContent -RelativePath "Prompts\orchestrator.skprompt.txt.template" -Tokens $tokens) -AllowOverwrite:$Force

$featureTemplate = if ($IncludeDatabase) { "Features\Sample.database.feature.template" } else { "Features\Sample.feature.template" }
Write-FileSafely -Path (Join-Path $projectRoot "Features\Sample.feature") -Content (Get-TemplateContent -RelativePath $featureTemplate -Tokens $tokens) -AllowOverwrite:$Force

$hooksTemplate = if ($IncludeDatabase) { "Hooks\TestLifecycleHooks.database.cs.template" } else { "Hooks\TestLifecycleHooks.cs.template" }
Write-FileSafely -Path (Join-Path $projectRoot "Hooks\TestLifecycleHooks.cs") -Content (Get-TemplateContent -RelativePath $hooksTemplate -Tokens $tokens) -AllowOverwrite:$Force

if ($UsePrivatePackages) {
    Write-FileSafely -Path (Join-Path $projectRoot "Drivers\Aws\AwsClientFactory.cs") -Content (Get-TemplateContent -RelativePath "Drivers\Aws\AwsClientFactory.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
    Write-FileSafely -Path (Join-Path $projectRoot "Drivers\Aws\SecretsManagerWrapper.cs") -Content (Get-TemplateContent -RelativePath "Drivers\Aws\SecretsManagerWrapper.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
    Write-FileSafely -Path (Join-Path $projectRoot "Tests\AwsConnectionTest.cs") -Content (Get-TemplateContent -RelativePath "Tests\AwsConnectionTest.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
}

if ($IncludeDatabase) {
    Write-FileSafely -Path (Join-Path $projectRoot "Skills\DatabaseSkill.cs") -Content (Get-TemplateContent -RelativePath "Skills\DatabaseSkill.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
    Write-FileSafely -Path (Join-Path $projectRoot "StepDefinitions\DatabaseStepDefinitions.cs") -Content (Get-TemplateContent -RelativePath "StepDefinitions\DatabaseStepDefinitions.cs.template" -Tokens $tokens) -AllowOverwrite:$Force
}

Write-Section "Generando solucion"

Push-Location $repoRoot
try {
    if (-not (Test-Path $solutionPath)) {
    dotnet new sln -n $ProjectName | Out-Host
    }

    $projectFile = Join-Path $projectRoot "$ProjectName.csproj"
    dotnet sln $solutionPath add $projectFile | Out-Host
}
finally {
    Pop-Location
}

if (-not $SkipRestore) {
    Write-Section "Validando restore y build"

    if ($UsePrivatePackages) {
        $token = $env:VSTS_GITHUB_ACCESS_KEY
        if ([string]::IsNullOrWhiteSpace($token)) {
            $token = Get-TokenFromUserScope
            if (-not [string]::IsNullOrWhiteSpace($token)) {
                $env:VSTS_GITHUB_ACCESS_KEY = $token
            }
        }

        if ([string]::IsNullOrWhiteSpace($env:VSTS_GITHUB_ACCESS_KEY)) {
            throw "Se requiere VSTS_GITHUB_ACCESS_KEY para restaurar paquetes privados. Usa -SkipRestore o configura el token."
        }
    }

    Push-Location $projectRoot
    try {
        dotnet restore
        if ($LASTEXITCODE -ne 0) {
            throw "dotnet restore fallo."
        }

        dotnet build --configuration Release
        if ($LASTEXITCODE -ne 0) {
            throw "dotnet build fallo."
        }
    }
    finally {
        Pop-Location
    }
}

Write-Section "Bootstrap completado"
Write-Host "Proyecto generado en: $projectRoot" -ForegroundColor Green
Write-Host "Solucion: $solutionPath" -ForegroundColor Green
Write-Host ""
Write-Host "Siguientes pasos recomendados:" -ForegroundColor Yellow
Write-Host "  1. Revisar appsettings.json y reemplazar placeholders." -ForegroundColor White
Write-Host "  2. Si aplica, configurar secretos por variables de entorno." -ForegroundColor White
Write-Host "  3. Ejecutar dotnet test --configuration Release cuando el proyecto este listo." -ForegroundColor White
