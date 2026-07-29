. .\Scripts\NewModuleConfig\Public\New-RCSamplerModule.ps1

Import-Module Plaster

#Install-Module -Name Plaster -Repository PSGallery -MaximumVersion 1.1.4 -SkipPublisherCheck

$RootDest = "C:\Users\rcarpen\Repos\CodeForge-PE"
$ModuleName = "PEMonoRepo"

$ProjectPath = Join-Path $RootDest $ModuleName
$copyPath = (Resolve-Path .\CopyToProject\)




$paramHash = @{
    RootDest          = $RootDest
    ModuleName        = $ModuleName
    Description       = "Shared PowerShell toolkit for Production Engineering tasks."
    SourceDirectory   = "Source"
    ModuleAuthor      = "Production Engineering"
    ModuleVersion     = "1.0.0"
    LicenseType       = "MIT"
    CustomRepo        = "PSGallery"
    MainGitBranch     = "main"
    License           = $false
    UseGit            = $true
    UseGitVersion     = $true
    UseVSCode         = $true
    UseCodeCovIo      = $false
    UseGitHub         = $false
    UseAzurePipelines = $True
    #GitHubOwner       = "Ryan Carpenter"
    Features          = @("Classes", "git", "ModuleQuality", "Build")
}

# Use the paramHash with New-PublicModule
New-RCSamplerModule @paramHash


Get-childItem  $CopyPath |Copy-Item -Destination $ProjectPath -Recurse -Force



Install-Module -Name 'Sampler' -Scope 'CurrentUser'

$newSampleModuleParameters = @{
   DestinationPath   = 'C:\Temp'
   ModuleType        = 'SimpleModule'
   ModuleName        = 'TestModule'
   ModuleAuthor      = 'Prod Eng'
   ModuleDescription = 'Prod Eng Test'
}

New-SampleModule @newSampleModuleParameters
