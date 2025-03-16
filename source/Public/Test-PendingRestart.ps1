<#
    .SYNOPSIS
        Tests if the computer is pending a restart.

    .DESCRIPTION
        This function checks various registry locations, the Component-Based
        Servicing, Windows Update, Pending File Rename Operations, Pending Computer
        Rename, Pending Domain Join, and SCCM Client to determine if the computer
        is pending a restart.

    .PARAMETER Check
        Specifies which pending restart checks to perform. Multiple values can be
        specified by using the bitwise OR operator. By default, all checks are performed.

        Available options are:
        - ComponentBasedServicing: Checks Component-Based Servicing registry key
        - WindowsUpdate: Checks Windows Update Auto Update registry key
        - PendingFileRename: Checks PendingFileRenameOperations registry key
        - PendingComputerRename: Checks for pending computer rename
        - PendingDomainJoin: Checks for pending domain join
        - ConfigurationManagerClient: Checks Configuration Manager client for pending reboots
        - All: Performs all checks (default)

    .EXAMPLE
        Test-PendingRestart

        Returns $true if the computer is pending a restart, otherwise returns $false.

    .EXAMPLE
        Test-PendingRestart -Check WindowsUpdate, ComponentBasedServicing

        Checks only Windows Update and Component-Based Servicing for pending restarts.
        Returns $true if either condition requires a restart, otherwise returns $false.

    .OUTPUTS
        [System.Boolean]

    .NOTES
        This command checks for the following conditions:
        - Windows Update Auto Update (RebootRequired)
        - Component-Based Servicing (RebootPending)
        - Pending File Rename Operations
        - Pending Computer Rename
        - Pending Domain Join
        - Pending SCCM Client Reboot
#>
function Test-PendingRestart
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [PendingRestartCheck]
        $Check = [PendingRestartCheck]::All
    )

    # cSpell:ignore SCCM
    if ($IsWindows -or $PSEdition -eq 'Desktop')
    {
        $pendingRestart = $false
        $cbsRebootPending = $false
        $windowsUpdateRebootRequired = $false
        $pendingFileRename = $false
        $pendingComputerRename = $false
        $pendingDomainJoin = $false
        $pendingCcmReboot = $false

        # Check Component-Based Servicing (CBS) registry key.
        if ($Check -band [PendingRestartCheck]::ComponentBasedServicing)
        {
            $getRegistryPropertyValueParameters = @{
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
                Name = '*'
            }

            $cbsRebootPending = $null -ne (Get-RegistryPropertyValue @getRegistryPropertyValueParameters)
        }

        # Check Windows Update Auto Update registry key.
        if ($Check -band [PendingRestartCheck]::WindowsUpdate)
        {
            $getRegistryPropertyValueParameters = @{
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
                Name = '*'
            }

            $windowsUpdateRebootRequired = $null -ne (Get-RegistryPropertyValue @getRegistryPropertyValueParameters)
        }

        <#
            Check PendingFileRenameOperations registry key. If the key 'PendingFileRenameOperations'
            does not exist then it should return $false, otherwise it should return $true.
        #>
        if ($Check -band [PendingRestartCheck]::PendingFileRename)
        {
            $getRegistryPropertyValueParameters = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
                Name = 'PendingFileRenameOperations'
            }

            $pendingFileRename = $null -ne (Get-RegistryPropertyValue @getRegistryPropertyValueParameters)
        }

        # Check for pending computer rename.
        if ($Check -band [PendingRestartCheck]::PendingComputerRename)
        {
            $activeComputerName = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Name 'ComputerName' -ErrorAction 'SilentlyContinue'
            $pendingComputerName = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -Name 'ComputerName' -ErrorAction 'SilentlyContinue'

            if ($activeComputerName -and $pendingComputerName)
            {
                $pendingComputerRename = $activeComputerName.ComputerName -ne $pendingComputerName.ComputerName
            }
        }

        # Check for pending domain join. cSpell:ignore Netlogon
        if ($Check -band [PendingRestartCheck]::PendingDomainJoin)
        {
            $getRegistryPropertyValueParameters = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon'
                Name = 'JoinDomain'
            }

            $pendingDomainJoin = $null -ne (Get-RegistryPropertyValue @getRegistryPropertyValueParameters)
        }

        # Check Configuration Manager client.
        if ($Check -band [PendingRestartCheck]::ConfigurationManagerClient)
        {
            $getRegistryPropertyValueParameters = @{
                Path = 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData'
                Name = '*'
            }

            $pendingCcmReboot = $null -ne (Get-RegistryPropertyValue @getRegistryPropertyValueParameters)
        }

        # If any of the above criteria are true, set pendingRestart to true
        if ($cbsRebootPending -or $windowsUpdateRebootRequired -or $pendingFileRename -or $pendingComputerRename -or $pendingDomainJoin -or $pendingCcmReboot)
        {
            $pendingRestart = $true
        }

        return $pendingRestart
    }
    else
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Test_PendingRestart_UnsupportedOs
            Category     = 'InvalidOperation'
            ErrorId      = 'TPR0001' # cSpell: disable-line
            TargetObject = $DatabaseName
        }

        Write-Error @writeErrorParameters

        return $false
    }
}
