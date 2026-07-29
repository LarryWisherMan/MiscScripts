param
(
    # Base directory of all output (default to 'output')
    [Parameter()]
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName '' ),

    [Parameter()]
    [System.String]
    $ModuleVersion = (property ModuleVersion ""),

    [Parameter()]
    [string]
    $PackageToken = (property PackageToken ''),

    [Parameter()]
    [string]
    $OrgName = (property OrgName "$($buildInfo.ProjectConfig.Organization)"),

    [Parameter()]
    $AzureProjectName = (property AzureProjectName "$($buildInfo.ProjectConfig.Project)"),

    [Parameter()]
    $ArtifactFeed = (property ArtifactFeed "$($buildInfo.ProjectConfig.FeedName)"),

    [Parameter()]
    $SkipPublish = (property SkipPublish '')
)

Task InitGit {
    . Set-SamplerTaskVariable -AsNewBuild

    git init
    git add .
    git commit -m "Initial commit - $ProjectName  module"

}

Task Git_LinkToRemote {

    . Set-SamplerTaskVariable -AsNewBuild

    $AzureProjectName = [uri]::EscapeDataString($AzureProjectName)

    $RemoteUrl = "https://dev.azure.com/{0}/{1}/_git/{2}" -f $OrgName, $AzureProjectName, $ProjectName

    git remote add origin $RemoteUrl
    git branch -M main
    git push -u origin main


}
