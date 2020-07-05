<#
    .SYNOPSIS
        Sets the global DSCMachineStatus variable to a value of 1 to
        indicate to the LCM that a reboot of the node is required by
        this resource.

    .EXAMPLE
        Set-DscMachineRebootRequired

    .NOTES
        This function is implemented so that individual resource modules
        do not need to use and therefore suppress Global variables
        directly. It also enables mocking to increase testability of
        consumers.
#>
function Set-DscMachineRebootRequired
{
    # Suppressing this rule because $global:DSCMachineStatus is used to trigger a reboot.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    <#
        Suppressing this rule because $global:DSCMachineStatus is only set,
        never used (by design of Desired State Configuration).
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding()]
    param
    (
    )

    $global:DSCMachineStatus = 1
}
