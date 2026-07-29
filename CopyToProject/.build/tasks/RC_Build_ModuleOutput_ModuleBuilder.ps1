param
(
    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath ''),

    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

    [Parameter()]
    [System.String]
    $BuildModuleOutput = (property BuildModuleOutput (Join-Path $OutputDirectory $BuiltModuleSubdirectory)),

    [Parameter()]
    [System.String]
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [System.String]
    $ModuleVersion = (property ModuleVersion ''),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

Task RC_Build_ModuleOutput_ModuleBuilder {
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable -AsNewBuild

    Import-Module -Name ModuleBuilder -ErrorAction 'Stop'

    $buildModuleParams = @{}

    foreach ($paramName in (Get-Command -Name Build-Module).Parameters.Keys)
    {
        if ($paramName -eq 'SourcePath')
        {
            <#
                To support building the without a build manifest the SourcePath must be
                set to the path to the source module manifest.
            #>
            $buildModuleParams.Add($paramName, $moduleManifestPath)
        }
        else
        {
            $valueFromBuildParam = Get-Variable -Name $paramName -ValueOnly -ErrorAction 'SilentlyContinue'
            $valueFromBuildInfo = $BuildInfo[$paramName]

            <#
                If Build-Module parameters are available in current session, use those
                otherwise use params from BuildInfo if specified.
            #>
            if ($valueFromBuildParam)
            {
                Write-Build -Color 'DarkGray' -Text "Adding $paramName with value $valueFromBuildParam from current Variables"

                if ($paramName -eq 'OutputDirectory')
                {
                    $buildModuleParams.Add($paramName, (Join-Path -Path $BuildModuleOutput -ChildPath $ProjectName))
                }
                else
                {
                    $buildModuleParams.Add($paramName, $valueFromBuildParam)
                }
            }
            elseif ($valueFromBuildInfo)
            {
                Write-Build -Color 'DarkGray' "Adding $paramName with value $valueFromBuildInfo from Build Info"

                $buildModuleParams.Add($paramName, $valueFromBuildInfo)
            }
            else
            {
                Write-Debug -Message "No value specified for $paramName"
            }
        }
    }

    Write-Build -Color 'Green' -text "Building Module to $($buildModuleParams['OutputDirectory'])..."

    if (-not $buildModuleParams.ContainsKey('SemVer'))
    {
        $buildModuleParams.Add('SemVer', $ModuleVersion)
    }


    Write-Build -color "green" -text ($buildModuleParams | Out-String)

    #(Get-Content -Raw $buildModuleParams.SourcePath) | Set-Content -Encoding UTF8 -Path $buildModuleParams.SourcePath


    Write-Build -color "Yellow" -text (Test-ModuleManifest $buildModuleParams.SourcePath -Verbose | Out-String)

    $BuiltModule = Build-Module @buildModuleParams -PassThru

    # if we built the PSM1 on Windows with a BOM, re-write without BOM
    if ($PSVersionTable.PSVersion.Major -le 5)
    {
        if (Split-Path -IsAbsolute -Path $BuiltModule.RootModule)
        {
            $Psm1Path = $BuiltModule.RootModule
        }
        else
        {
            $Psm1Path = Join-Path -Path $BuiltModule.ModuleBase -ChildPath $BuiltModule.RootModule
        }

        $RootModuleDefinition = Get-Content -Raw -Path $Psm1Path
        [System.IO.File]::WriteAllLines($Psm1Path, $RootModuleDefinition)
    }

    if (Test-Path -Path $ReleaseNotesPath)
    {
        $releaseNotes = Get-Content -Path $ReleaseNotesPath -Raw

        $outputManifest = $BuiltModule.Path

        Update-Metadata -Path $outputManifest -PropertyName 'PrivateData.PSData.ReleaseNotes' -Value $releaseNotes
    }
}
