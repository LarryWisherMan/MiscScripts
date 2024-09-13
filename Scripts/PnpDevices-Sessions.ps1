function New-ComputerSession
{
    <#
    .SYNOPSIS
        Creates a new CIM, PS session, or both to one or more specified computers.

    .DESCRIPTION
        The New-ComputerSession function attempts to create new remote CIM and/or PS sessions to one or more specified computers based on the provided switches.
        If no computer name is provided, it defaults to the local computer.
        The function returns a hashtable where each key is the ComputerName, and the value is a nested hashtable containing both `CimSession`, `PSSession`, and an error message (if any).

    .PARAMETER ComputerName
        The name(s) of the computer(s) to which the session should be created. If not specified, the local computer is used.
        You can provide one or more computer names as an array or pipeline input.

    .PARAMETER UseCimSession
        Switch to create a CIM session. This switch can be combined with `UsePSSession` to create both sessions.

    .PARAMETER UsePSSession
        Switch to create a PS session. This switch can be combined with `UseCimSession` to create both sessions.

    .EXAMPLE
        New-ComputerSession -ComputerName "Server01" -UseCimSession

        This example attempts to create a remote CIM session to the computer named "Server01".
        It returns a hashtable with the computer name as the key and the session information or error message.

    .EXAMPLE
        New-ComputerSession -ComputerName "Server01", "Server02" -UsePSSession

        This example attempts to create PS sessions for both "Server01" and "Server02".
        The result is a hashtable with each computer name as the key and the session/error information.

    .EXAMPLE
        New-ComputerSession -ComputerName "Server01", "Server02" -UseCimSession -UsePSSession

        This example attempts to create both CIM and PS sessions for "Server01" and "Server02".
        The result is a hashtable with each computer name as the key and the session/error information for both session types.

    .OUTPUTS
        System.Collections.Hashtable
        A hashtable where each key is a ComputerName, and the value is another hashtable containing:
        - CimSession: The CIM session object if successful, otherwise $null.
        - PSSession: The PS session object if successful, otherwise $null.
        - ErrorMessage: The error message if the session creation fails, otherwise $null.

    .NOTES
        The returned hashtable uses the computer names as keys.
        Each key maps to a nested hashtable containing:
        - CimSession: The CIM session object.
        - PSSession: The PS session object.
        - ErrorMessage: Any error message from session creation.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Use this switch to create CIM sessions.")]
        [switch]$UseCimSession,

        [Parameter(Mandatory = $false, HelpMessage = "Use this switch to create PS sessions.")]
        [switch]$UsePSSession
    )

    # Begin block (initialization, runs once)
    begin
    {
        Write-Verbose "Initializing session creation..."
        # Initialize a hashtable to hold the results with ComputerName as the key
        $Results = @{}

        # If neither switch is provided, we will default to creating both types of sessions
        if (-not $UseCimSession -and -not $UsePSSession)
        {
            $UseCimSession = $true
            $UsePSSession = $true
        }
    }

    # Process block (handles pipeline input, automatically iterates over array elements)
    process
    {
        foreach ($name in $ComputerName)
        {
            if (-not $name)
            {
                Write-Verbose "No ComputerName provided - running locally on $($env:COMPUTERNAME)"
                $name = $env:COMPUTERNAME
            }

            # Initialize variables for each session type
            $CimSession = $null
            $PSSession = $null
            $errorMessage = $null

            try
            {
                # Create the CIM session if requested
                if ($UseCimSession)
                {
                    try
                    {
                        $CimSession = New-CimSession -ComputerName $name -ErrorAction Stop
                        Write-Verbose "CIM session created for $name"
                    }
                    catch
                    {
                        $errorMessage = "Failed to create CIM session for $name. Error: $_.Exception.Message"
                        Write-Verbose $errorMessage
                    }
                }

                # Create the PS session if requested
                if ($UsePSSession)
                {
                    try
                    {
                        $PSSession = New-PSSession -ComputerName $name -ErrorAction Stop
                        Write-Verbose "PS session created for $name"
                    }
                    catch
                    {
                        $psError = "Failed to create PS session for $name. Error: $_.Exception.Message"
                        Write-Verbose $psError

                        # Append PS session error to the error message
                        if ($errorMessage)
                        {
                            $errorMessage += " | $psError"
                        }
                        else
                        {
                            $errorMessage = $psError
                        }
                    }
                }

                # Build the result object
                $result = @{
                    CimSession   = $CimSession
                    PSSession    = $PSSession
                    ErrorMessage = $errorMessage
                }
            }
            catch
            {
                $errorMessage = $_.Exception.Message
                Write-Verbose "Failed to create session for $name. Error: $errorMessage"

                # Return object with no session and the error message
                $result = @{
                    CimSession   = $null
                    PSSession    = $null
                    ErrorMessage = $errorMessage
                }
            }

            # Add each result to the hashtable with ComputerName as the key
            $Results[$name] = $result
        }
    }

    # End block (returns the hashtable, runs once after all input is processed)
    end
    {
        Write-Verbose "Session creation process completed."
        # Output the hashtable with ComputerName as the key
        $Results
    }
}

function Get-PnpDevicesForSessions
{
    <#
.SYNOPSIS
    Retrieves PnP devices for each computer with a valid CIM session.

.DESCRIPTION
    The Get-PnpDevicesForSessions function accepts a hashtable containing CIM session data.
    For each valid CIM session, it attempts to retrieve PnP devices using the Get-PnpDevice cmdlet.
    If the session is invalid (null), it skips the PnP device retrieval and logs the result.
    The function accepts input either directly or from the pipeline.

.PARAMETER SessionData
    A hashtable containing CIM session information for multiple computers.
    The keys are the computer names, and each value is another hashtable with session data under the 'Session' key.

.EXAMPLE
    $sessionData = New-ComputerSession -ComputerName "Server01", "Server02"
    $updatedData = Get-PnpDevicesForSessions -SessionData $sessionData

    This example creates CIM sessions for "Server01" and "Server02", then retrieves their PnP devices if the sessions are valid.

.EXAMPLE
    $sessionData | Get-PnpDevicesForSessions

    This example demonstrates piping session data directly into the function.

.OUTPUTS
    System.Collections.Hashtable
    A hashtable where each key is a computer name and the value contains session details and PnP devices.

.NOTES
    The output hashtable will contain the original session data plus a new field, 'PnpDevices', which stores the result of the Get-PnpDevice cmdlet.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$SessionData
    )

    # Begin block - runs once before processing pipeline input
    begin
    {
        Write-Verbose "Starting to process session data..."
        $Results = @{}
    }

    # Process block - runs once for each piped input item
    process
    {
        # Iterate over each computer in the session data
        foreach ($key in $SessionData.Keys)
        {
            $ComputerName = $key
            $CimSession = $SessionData[$ComputerName].CimSession

            # Check if the CIM session exists
            if ($CimSession)
            {
                Write-Verbose "Fetching PnP devices for $ComputerName"
                try
                {
                    $SessionData[$ComputerName].PnpDevices = Get-PnpDevice -CimSession $CimSession
                }
                catch
                {
                    Write-Warning "Failed to retrieve PnP devices for $ComputerName. Error: $_"
                    $SessionData[$ComputerName].PnpDevices = $null
                }
            }
            else
            {
                Write-Verbose "No CIM session available for $ComputerName. Skipping PnP device query."
                $SessionData[$ComputerName].PnpDevices = $null
            }
        }

        # Add the processed session data to the result
        $Results += $SessionData
    }

    # End block - runs after all pipeline input has been processed
    end
    {
        Write-Verbose "Finished processing session data."
        # Output the updated hashtable with PnP devices added
        return $Results
    }
}

function Remove-PnpDeviceFromSession
{
    <#
    .SYNOPSIS
        Removes PnP devices using a PSSession on a local or remote computer and performs a single scan after removal.

    .DESCRIPTION
        The Remove-PnpDeviceFromSession function removes specified PnP devices on either a local or remote computer using the provided PSSession.
        After all devices are removed, the function runs `pnputil /scan-devices` once to ensure that the system performs a device scan after the removals.
        The function returns a custom object that contains details about the removal operation for each device and the result of the scan operation.

    .PARAMETER PSSession
        The PSSession representing the local or remote computer where the PnP devices will be removed and scanned.
        Use `New-PSSession` to create a PSSession for either local or remote computers.

    .PARAMETER Devices
        A collection of devices (`PSCustomObject[]`) that includes the DeviceID and other details such as Name, Description, Class, and SystemName.
        Each device's `DeviceID` is used to remove the device via the `pnputil` command.

    .EXAMPLE
        # Create a local PSSession
        $localPSSession = New-PSSession -ComputerName $env:COMPUTERNAME

        # Get PnP devices
        $devices = Get-PnpDevice -CimSession $localCimSession

        # Remove PnP devices and run a single scan on the local machine
        $results = Remove-PnpDeviceFromSession -PSSession $localPSSession -Devices $devices

        # View the results
        $results

        This example retrieves the PnP devices from the local machine using a PSSession, removes them, and performs a single device scan after all removals. 
        The results will show the success or failure of each device removal and the scan completion status.

    .EXAMPLE
        # Create a remote PSSession
        $remotePSSession = New-PSSession -ComputerName "RemoteServer"

        # Get PnP devices
        $devices = Get-PnpDevice -CimSession $remoteCimSession

        # Remove PnP devices and run a single scan on the remote machine
        $results = Remove-PnpDeviceFromSession -PSSession $remotePSSession -Devices $devices

        # View the results
        $results

        This example retrieves the PnP devices from a remote machine using a PSSession, removes them, and performs a single device scan after all removals. 
        The results will show the success or failure of each device removal and the scan completion status.

    .OUTPUTS
        PSCustomObject[]
        The function returns an array of custom objects where each object contains:
        - DeviceID: The ID of the removed device.
        - Name: The name of the device.
        - Description: A description of the device.
        - Class: The class of the device (e.g., USB, Audio).
        - ComputerName: The name of the computer where the device was removed.
        - Output: The output of the `pnputil /remove-device` command.
        - Success: Indicates whether the device was successfully removed (True/False).
        - ScanCompleted: Indicates whether the scan completed successfully after all device removals (True/False).

    .NOTES
        This function uses `pnputil`, a Windows utility, to remove devices and scan the system for hardware changes. Ensure you have the necessary permissions to execute this command on the local or remote machine.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$PSSession,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Devices
    )

    # Define the script block for device removal and a single scan
    $SB = {
        param(
            [PSCustomObject[]]$Devices
        )

        # Create an empty array to hold the results
        $results = @()

        # Remove each device in the Devices array
        foreach ($Device in $Devices)
        {
            $DeviceID = $Device.DeviceID

            # Execute pnputil to remove the device
            $output = pnputil /remove-device $DeviceID 2>&1

            # Capture the result and details in a custom object
            $deviceResult = [PSCustomObject]@{
                DeviceID     = $DeviceID
                Name         = $Device.Name
                Description  = $Device.Description
                Class        = $Device.Class
                ComputerName = $Device.SystemName
                Output       = $output
                Success      = if ($output -match "*successfully") { $true } else { $false }
            }

            # Add the result to the results array
            $results += $deviceResult
        }

        # Perform a device scan after all devices are removed
        $scanOutput = pnputil /scan-devices 2>&1

        # Capture the scan result
        $scanCompleted = if ($scanOutput -match "Scan complete") { $true } else { $false }

        # Return the results along with the scan completion status
        [PSCustomObject]@{
            Devices       = $results
            ScanCompleted = $scanCompleted
        }
    }

    # Invoke the script block, regardless of local or remote PSSession
    $removedDevices = Invoke-Command -Session $PSSession -ScriptBlock $SB -ArgumentList $Devices

    # Return the results of the removal process and scan
    return $removedDevices
}

function Scan-PnpDevicesFromSession
{
    <#
    .SYNOPSIS
        Scans for devices using a PSSession on a local or remote computer.

    .DESCRIPTION
        The Scan-PnpDevicesFromSession function uses the `pnputil /scan-devices` command to scan for devices on either a local or remote computer via the provided PSSession.
        The function returns the output of the scan and additional information about the computer on which the scan was performed.

    .PARAMETER PSSession
        The PSSession representing the local or remote computer where the device scan will be performed.
        Use `New-PSSession` to create a PSSession for either local or remote computers.

    .EXAMPLE
        # Create a local PSSession
        $localPSSession = New-PSSession -ComputerName $env:COMPUTERNAME

        # Scan devices on the local machine
        $results = Scan-PnpDevicesFromSession -PSSession $localPSSession

        # View the results
        $results

        This example scans devices on the local machine and returns the results of the `pnputil /scan-devices` command.

    .EXAMPLE
        # Create a remote PSSession
        $remotePSSession = New-PSSession -ComputerName "RemoteServer"

        # Scan devices on the remote machine
        $results = Scan-PnpDevicesFromSession -PSSession $remotePSSession

        # View the results
        $results

        This example scans devices on a remote machine and returns the results of the `pnputil /scan-devices` command.

    .OUTPUTS
        PSCustomObject
        The function returns a custom object containing:
        - ComputerName: The name of the computer where the scan was performed.
        - Output: The output of the `pnputil /scan-devices` command.
        - Success: Indicates whether the scan was successful (True/False).

    .NOTES
        This function uses `pnputil`, a Windows utility, to scan devices on the system. Ensure you have the necessary permissions to execute this command on the local or remote machine.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$PSSession
    )

    # Define the script block for scanning devices
    $SB = {
        # Execute pnputil to scan devices
        $output = pnputil /scan-devices 2>&1

        # Capture the result and details in a custom object
        $result = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Output       = $output
            Success      = if ($output -match "Scan complete")
            {
                $true 
            }
            else
            {
                $false 
            }
        }

        # Return the result
        return $result
    }

    # Invoke the script block, regardless of local or remote PSSession
    $scanResult = Invoke-Command -Session $PSSession -ScriptBlock $SB

    # Return the scan results
    return $scanResult
}



<#
Example with Get-PNPDevice

$RemoteComputer = read-host "Enter Remote ComputerName"
$Local = $env:ComputerName

#Create Sessions and Get PNPDevices
$sessionData = New-ComputerSession -ComputerName $RemoteComputer, $Local -UseCimSession -UsePSSession  | Get-PnpDevicesForSessions
$sessionData = $sessionData | Get-PnpDevicesForSessions

#return pnpDevices
$sessionData.$RemoteComputer.PnpDevices
$sessionData.$Local.PnpDevices


#Scan from Session Example
Scan-PnpDevicesFromSession  -PSSession $sessionData.$Local.PSSession
Scan-PnpDevicesFromSession  -PSSession $sessionData.$RemoteComputer.PSSession


#>





