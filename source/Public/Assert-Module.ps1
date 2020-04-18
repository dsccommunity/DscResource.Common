<#
    .SYNOPSIS
        Assert if the specific module is available to be imported.

    .PARAMETER ModuleName
        Specifies the name of the module to assert.

    .PARAMETER ImportModule
        Specfiies to import the module if it is asserted.
        
    .EXAMPLE
        Assert-Module -ModuleName 'DhcpServer'

        This asserts that the module DhcpServer is available on the system.
#>
function Assert-Module
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,
        
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ImportModule
    )

    if (-not (Get-Module -Name $ModuleName -ListAvailable))
    {
        $errorMessage = $script:localizedData.ModuleNotFound -f $ModuleName
        New-ObjectNotFoundException -Message $errorMessage
    }
    
    if ($ImportModule)
    {
        Import-Module -Name $ModuleName
    }
}
