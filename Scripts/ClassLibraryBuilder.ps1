param(
    [string]$ProjectName = "PowerShellNova",
    [string]$BasePath = "D:\1_Code\GithubRepos"
)


# Calculate the project root directory
$ProjectRoot = Join-Path $BasePath $ProjectName

# Function to create a file and ensure its directory exists
function New-FileStructure
{
    param (
        [string]$Path,
        [string]$Content = ""
    )

    $Directory = Split-Path $Path
    if (!(Test-Path $Directory))
    {
        New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    }

    Set-Content -Path $Path -Value $Content
}

# Begin project setup
Write-Host "Setting up $ProjectName project at $ProjectRoot using dotnet CLI..." -ForegroundColor Cyan

# Ensure the base path exists
if (!(Test-Path $BasePath))
{
    New-Item -ItemType Directory -Path $BasePath | Out-Null
}

# Create the solution directory
if (!(Test-Path $ProjectRoot))
{
    New-Item -ItemType Directory -Path $ProjectRoot | Out-Null
}

# Navigate to the project root
Set-Location $ProjectRoot

# Create the solution file in the root
Write-Host "Creating solution file..."
dotnet new sln --name $ProjectName

# Create the src folder and projects inside it
$SrcPath = Join-Path $ProjectRoot "src"
New-Item -ItemType Directory -Path $SrcPath | Out-Null

Write-Host "Creating Core project..."
dotnet new classlib --name "$ProjectName.Core" --framework net8.0 --output "$SrcPath\$ProjectName.Core"
dotnet sln add "$SrcPath\$ProjectName.Core\$ProjectName.Core.csproj"

Write-Host "Creating Infrastructure project..."
dotnet new classlib --name "$ProjectName.Infrastructure" --framework net8.0 --output "$SrcPath\$ProjectName.Infrastructure"
dotnet sln add "$SrcPath\$ProjectName.Infrastructure\$ProjectName.Infrastructure.csproj"

# Create the tests folder and test project
$TestsPath = Join-Path $ProjectRoot "tests"
New-Item -ItemType Directory -Path $TestsPath | Out-Null

Write-Host "Creating Test project..."
dotnet new xunit --name "$ProjectName.Tests" --framework net8.0 --output "$TestsPath\$ProjectName.Tests"
dotnet sln add "$TestsPath\$ProjectName.Tests\$ProjectName.Tests.csproj"

# Add references between projects
Write-Host "Adding references between projects..."
dotnet add "$SrcPath\$ProjectName.Infrastructure\$ProjectName.Infrastructure.csproj" reference "$SrcPath\$ProjectName.Core\$ProjectName.Core.csproj"
dotnet add "$TestsPath\$ProjectName.Tests\$ProjectName.Tests.csproj" reference "$SrcPath\$ProjectName.Core\$ProjectName.Core.csproj"

# Create essential build and configuration files in the root
New-FileStructure "$ProjectRoot\build\build.ps1" "Write-Host 'Running build process for $ProjectName...'"
New-FileStructure "$ProjectRoot\.azure-pipelines.yml" "# Azure DevOps pipeline configuration for $ProjectName"
New-FileStructure "$ProjectRoot\Directory.Build.Props" "<Project><PropertyGroup><TargetFramework>net8.0</TargetFramework></PropertyGroup></Project>"
New-FileStructure "$ProjectRoot\Directory.Build.Targets" "<Project><Target Name='PostBuild' AfterTargets='Build'><Message Text='Build complete!' /></Target></Project>"
New-FileStructure "$ProjectRoot\Directory.Packages.Props" "<Project><ItemGroup><PackageReference Include='Newtonsoft.Json' Version='13.0.1' /></ItemGroup></Project>"
New-FileStructure "$ProjectRoot\version.json" '{ "Major": 1, "Minor": 0, "Patch": 0, "Prerelease": "beta" }'
New-FileStructure "$ProjectRoot\nuget.config" "<configuration><packageSources><add key='nuget.org' value='https://api.nuget.org/v3/index.json' /></packageSources></configuration>"
New-FileStructure "$ProjectRoot\LICENSE" "MIT License Placeholder"
New-FileStructure "$ProjectRoot\README.md" "# $ProjectName`nA C# class library project for $ProjectName."

Write-Host "Project setup for $ProjectName complete!" -ForegroundColor Green
