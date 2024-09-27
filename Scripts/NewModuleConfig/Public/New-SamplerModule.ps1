Function New-SamplerModule
{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RootDest = "D:\1_Code\GithubRepos",

        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$SourceDirectory = "source",

        [Parameter(Mandatory = $false)]
        [string]$ModuleAuthor = "LarryWisherMan",

        [Parameter(Mandatory = $false)]
        [string]$ModuleVersion = '0.0.1',

        [Parameter(Mandatory = $false)]
        [string]$LicenseType = 'MIT',

        [Parameter(Mandatory = $false)]
        [string]$CustomRepo = "PSGallery",

        [Parameter(Mandatory = $false)]
        [string]$MainGitBranch = "main",

        [Parameter(Mandatory = $false)]
        [bool]$License = $true,

        [Parameter(Mandatory = $false)]
        [bool]$UseGit = $true,

        [Parameter(Mandatory = $false)]
        [bool]$UseGitVersion = $true,

        [Parameter(Mandatory = $false)]
        [bool]$UseVSCode = $true,

        [Parameter(Mandatory = $false)]
        [bool]$UseCodeCovIo = $false,

        [Parameter(Mandatory = $false)]
        [bool]$UseGitHub = $true,

        [Parameter(Mandatory = $false)]
        [bool]$UseAzurePipelines = $true,

        [Parameter(Mandatory = $false)]
        [string]$GitHubOwner = "LarryWisherMan",

        [Parameter(Mandatory = $false)]
        [System.String[]]$Features
    )

    #Import-Module powershell-yaml  -ErrorAction SilentlyContinue

    #$samplerModule = Import-Module -Name Sampler -PassThru

    #TemplatePath
    #C:\Users\LWM\OneDrive\Documents\WindowsPowerShell\Modules\Sampler\0.118.1\Templates\Sampler\plasterManifest.xml

    $path = (resolve-Path -Path "$PSScriptRoot\..\Templates\Sampler\").Path

    $invokePlasterParameters = @{
        TemplatePath      = $path
        DestinationPath   = $RootDest
        ModuleType        = 'CustomModule'
        ModuleName        = $ModuleName
        SourceDirectory   = $SourceDirectory
        ModuleAuthor      = $ModuleAuthor
        ModuleVersion     = $ModuleVersion
        ModuleDescription = $Description
        License           = $License
        LicenseType       = $LicenseType
        CustomRepo        = $CustomRepo
        MainGitBranch     = $MainGitBranch
        UseGit            = $UseGit
        UseGitVersion     = $UseGitVersion
        UseVSCode         = $UseVSCode
        UseCodeCovIo      = $UseCodeCovIo
        UseGitHub         = $UseGitHub
        UseAzurePipelines = $UseAzurePipelines
        GitHubOwner       = $GitHubOwner
        Features          = $Features
    }

    Invoke-Plaster @invokePlasterParameters
}
