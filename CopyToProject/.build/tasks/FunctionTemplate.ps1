function Verb-Noun {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        #region Parameters

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$ExampleParameter

        #endregion Parameters
    )

    begin {
        #region Begin Block

        # Initialize any shared objects, collections, etc.

        #endregion Begin Block
    }

    process {
        #region Process Block

        if ($PSCmdlet.ShouldProcess("Target [$ExampleParameter]", "Perform action")) {
            try {
                # Core function logic here
            }
            catch {
                Write-Error -Message "Error in Verb-Noun: $($_.Exception.Message)"
                return
            }
        }

        #endregion Process Block
    }

    end {
        #region End Block

        # Finalization logic if needed

        #endregion End Block
    }
}
