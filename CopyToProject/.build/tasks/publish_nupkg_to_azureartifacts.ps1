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
    $AzureProjectName = (property ArtifactFeed "$($buildInfo.ProjectConfig.Project)"),

    [Parameter()]
    $ArtifactFeed = (property ArtifactFeed "$($buildInfo.ProjectConfig.FeedName)"),

    [Parameter()]
    $SkipPublish = (property SkipPublish '')
)



# Synopsis: Upload Nuget package to Azure Artifacts
#
Task Register_Azdo_PSFeed {

    . Set-SamplerTaskVariable -AsNewBuild
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #1
    #$env:SYSTEM_ACCESSTOKEN

    Write-Build -color "Yellow" -text "$ArtifactFeed"

    $ArtifactPublishSource = ("https://pkgs.dev.azure.com/{0}/{1}/_packaging/{2}/nuget/v2" -f @($orgname, ([uri]::EscapeDataString($AzureProjectName)), $ArtifactFeed))


    $uri = $ArtifactPublishSource

    $Repo = Get-PSRepository $ArtifactFeed -ErrorAction SilentlyContinue

    if ($Repo)
    {
        Write-Build -color "Yellow" -text "$ArtifactFeed Repo Already Registered. Overwritting..."

        $Repo | Unregister-PSRepository  -ErrorAction SilentlyContinue
    }

    if ($null -eq $env:SYSTEM_ACCESSTOKEN)
    {
        Import-Module safeguardapIModule -Force
        $accessToken = (Get-lhsUserSecret ProdEng-FullPat).GetNetworkCredential().password
    }
    else
    {
        $accessToken = $env:SYSTEM_ACCESSTOKEN
    }


    $token = $accessToken | ConvertTo-SecureString -AsPlainText -Force

    $credential = New-Object System.Management.Automation.PSCredential($ArtifactFeed, $token)


    $params = @{
        Name               = $ArtifactFeed
        SourceLocation     = $Uri
        PublishLocation    = $uri
        InstallationPolicy = 'Trusted'
        Credential         = $credential
    }

    Register-PSRepository  @Params

    $Repo | Unregister-PSRepository  -ErrorAction SilentlyContinue



    Write-Build -color "Yellow" -text  "$ArtifactFeed Registered: $uri"
}


Task Install_Module_from_Feed {
    . Set-SamplerTaskVariable -AsNewBuild
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #1

    $Repo = Get-PSResourceRepository -Name $ArtifactFeed -ErrorAction SilentlyContinue

    $ArtifactPublishSource = ("https://pkgs.dev.azure.com/{0}/{1}/_packaging/{2}/nuget/v2" -f @($orgname, ([uri]::EscapeDataString($AzureProjectName)), $ArtifactFeed))

    if ($null -eq $env:SYSTEM_ACCESSTOKEN)
    {
        Import-Module safeguardapIModule -Force
        $accessToken = (Get-lhsUserSecret ProdEng-FullPat).GetNetworkCredential().password
    }
    else
    {
        $accessToken = $env:SYSTEM_ACCESSTOKEN
    }


    if ($Repo)
    {
        Write-Build -color "Yellow" -text "$ArtifactFeed Repo Already Registered. Exiting..."
    }
    else
    {

        $params = @{
            Name    = $ArtifactFeed
            Uri     = $ArtifactPublishSource
            Trusted = $true

        }

        Register-PSResourceRepository @params

    }

    $token = $accessToken | ConvertTo-SecureString -AsPlainText -Force

    $credential = New-Object System.Management.Automation.PSCredential($accessToken, $token)

    $path = (Join-Path $OutputDirectory 'RequiredModules')

    Write-Build -color "Yellow"  -text "Path $path"

    $moduleName = "ApiUtils"
    Save-PSResource -Name $moduleName -Repository $ArtifactFeed -Path $Path -Credential $credential -Prerelease

    Unregister-PSResourceRepository -Name $ArtifactFeed

}
