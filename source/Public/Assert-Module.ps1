<#
    .SYNOPSIS
        Assert if the specific module is available to be imported.

    .PARAMETER ModuleName
        Specifies the name of the module to assert.

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
        $ModuleName
    )

    if (-not (Get-Module -Name $ModuleName -ListAvailable))
    {
        $errorMsg = $($script:localizedData.ModuleNotFound) -f $ModuleName

        New-TerminatingError -ErrorId 'ModuleNotFound' -ErrorMessage $errorMsg -ErrorCategory ObjectNotFound
    }
}
