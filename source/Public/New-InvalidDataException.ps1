<#
    .SYNOPSIS
        Creates and throws an invalid data exception.

    .DESCRIPTION
        Creates and throws an invalid data exception.

    .OUTPUTS
        None

    .PARAMETER ErrorId
        The error Id to assign to the exception.

    .PARAMETER Message
        The error message to assign to the exception.

    .EXAMPLE
        New-InvalidDataException -ErrorId 'InvalidDataError' -Message 'My error message'

        Creates and throws an invalid data exception with the error id 'InvalidDataError'
        and with the message 'My error message'.
#>
function New-InvalidDataException
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ErrorId,

        [Parameter(Mandatory = $true)]
        [Alias('ErrorMessage')]
        [System.String]
        $Message
    )

    $errorSplat = @{
        Exception     = [System.InvalidOperationException]::new($Message)
        ErrorId       = $ErrorId
        ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidData
    }

    throw (New-ErrorRecord @errorSplat)
}
