<#
    .SYNOPSIS
        Assert if the specific module is available to be imported and optionally
        import the module.

    .DESCRIPTION
        Assert if the specific module is available to be imported and optionally
        import the module. If the module is not available an exception will be
        thrown.

        See also `Test-ModuleExist`.

    .PARAMETER ModuleName
        Specifies the name of the module to assert.

    .PARAMETER ImportModule
        Specifies to import the module if it is asserted.

    .PARAMETER Force
        Specifies to forcibly import the module even if it is already in the
        session. This parameter is ignored unless parameter `ImportModule` is
        also used.

    .EXAMPLE
        Assert-Module -ModuleName 'DhcpServer'

        This asserts that the module DhcpServer is available on the system. If it
        is not an exception will be thrown.

    .EXAMPLE
        Assert-Module -ModuleName 'DhcpServer' -ImportModule

        This asserts that the module DhcpServer is available on the system and
        imports it. If the module is not available an exception will be thrown.

    .EXAMPLE
        Assert-Module -ModuleName 'DhcpServer' -ImportModule -Force

        This asserts that the module DhcpServer is available on the system and it
        will be forcibly imported into the session (even if it was already in the
        session). If the module is not available an exception will be thrown.
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
        $getModuleParameters = @{
            Name = $ModuleName
            ListAvailable = $true
        }

        # Add skip edition check for PSCore. Issue #131
        if ($PSVersionTable.PSVersion.Major -gt 5)
        {
            $getModuleParameters.SkipEditionCheck = $true
        }

        if (-not (Get-Module @getModuleParameters))
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
