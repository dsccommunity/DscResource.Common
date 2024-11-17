<#
    .SYNOPSIS
        Set the DSC reboot required status variable.

    .DESCRIPTION
        Sets the global DSCMachineStatus variable to a value of 1.
        This function is used to set the global variable that indicates
        to the LCM that a reboot of the node is required.

    .OUTPUTS
        None

    .EXAMPLE
        Set-DscMachineRebootRequired

        Sets the `$global:DSCMachineStatus` variable to 1.

    .NOTES
        This function is implemented so that individual resource modules
        do not need to use and therefore suppress Global variables
        directly. It also enables mocking to increase testability of
        consumers.
#>
function Set-DscMachineRebootRequired
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    # Suppressing this rule because $global:DSCMachineStatus is used to trigger a reboot.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    <#
        Suppressing this rule because $global:DSCMachineStatus is only set,
        never used (by design of Desired State Configuration).
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding()]
    param ()

    $global:DSCMachineStatus = 1
}
