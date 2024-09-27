. .\Scripts\NewModuleConfig\Public\New-SamplerModule.ps1


$paramHash = @{
    RootDest          = "D:\1_Code\AzureRepos\Production Engineering"
    ModuleName        = "EpicBcaModule"
    Description       = "Powershell Moudle for montioring and managing BCA Workstations"
    SourceDirectory   = "Source"
    ModuleAuthor      = "Ryan Carpenter"
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
    GitHubOwner       = "Ryan Carpenter"
    Features          = @("Classes", "git",  "ModuleQuality", "Build", "vscode" , "WorkspaceTasks")
}

# Use the paramHash with New-PublicModule
New-SamplerModule @paramHash


$paramHash = @{
    DestinationPath   = "D:\1_Code\GithubRepos"
    ModuleType        = 'CustomModule'
    ModuleName        = $ModuleName
    SourceDirectory   = "source"
    ModuleAuthor      = "LarryWisherMan"
    ModuleVersion     = '0.0.1'
    ModuleDescription = $Description
    License           = $true
    LicenseType       = 'MIT'
    CustomRepo        = "PSGallery"
    MainGitBranch     = "main"
    UseGit            = $true
    UseGitVersion     = $true
    UseVSCode         = $true
    UseCodeCovIo      = $false
    UseGitHub         = $true
    UseAzurePipelines = $true
    GitHubOwner       = "LarryWisherMan"
    $Features         = @("Classes", "git", "UnitTests", "ModuleQuality", "Build", "vscode" , "WorkspaceTasks")

}


$items = Get-item "D:\1_Code\GithubRepos\MiscScripts\Scripts\NewModuleConfig\Templates\VscodeConfig\_WorkSpaceTasks\*"


#rename items name by replaing - with _
foreach ($item in $items) {
    $newName = $item.Name -replace "-", "_"
    Rename-Item -Path $item.FullName -NewName $newName
}


#update reference to old names in D:\1_Code\GithubRepos\MiscScripts\Scripts\NewModuleConfig\Templates\VscodeConfig\WorkSpaceTasks.json

$filePath = "D:\1_Code\GithubRepos\MiscScripts\Scripts\NewModuleConfig\Templates\VscodeConfig\WorkSpaceTasks.json"
$workSpaceTasks = Get-Content -Path $filePath -Raw | ConvertFrom-Json
