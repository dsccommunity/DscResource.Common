<#
    .SYNOPSIS
        Assert if the specific module is available to be imported.

    .DESCRIPTION
        Assert if the specific module is available to be imported.

    .PARAMETER ModuleName
        Specifies the name of the module to assert.

    .PARAMETER ImportModule
        Specifies to import the module if it is asserted.

    .PARAMETER Force
        Specifies to forcibly import the module even if it is already in the
        session. THis parameter is ignored unless parameter `ImportModule` is
        also used.

    .EXAMPLE
        Assert-Module -ModuleName 'DhcpServer'

        This asserts that the module DhcpServer is available on the system.

    .EXAMPLE
        Assert-Module -ModuleName 'DhcpServer' -ImportModule

        This asserts that the module DhcpServer is available on the system and
        imports it.

    .EXAMPLE
        Assert-Module -ModuleName 'DhcpServer' -ImportModule -Force

        This asserts that the module DhcpServer is available on the system and
        forcibly imports it.
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
        $ImportModule,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    <#
        If the module is already in the session there is no need to use -ListAvailable.
        This is a fix for issue #66.
    #>
    if (-not (Get-Module -Name $ModuleName))
    {
        if (-not (Get-Module -Name $ModuleName -ListAvailable))
        {
            $errorMessage = $script:localizedData.ModuleNotFound -f $ModuleName
            New-ObjectNotFoundException -Message $errorMessage
        }

        # Only import it here if $Force is not set, otherwise it will be imported below.
        if ($ImportModule -and -not $Force)
        {
            Import-Module -Name $ModuleName
        }
    }

    # Always import the module even if already in session.
    if ($ImportModule -and $Force)
    {
        Import-Module -Name $ModuleName -Force
    }
}
