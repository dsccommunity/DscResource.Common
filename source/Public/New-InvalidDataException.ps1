<#
    .SYNOPSIS
        Creates and throws an invalid data exception.

    .DESCRIPTION
        Creates and throws an invalid data exception.

    .OUTPUTS
        None

    .PARAMETER ErrorId
        The error Id to assign to the exception.

    .PARAMETER ErrorMessage
        The error message to assign to the exception.

    .EXAMPLE
        New-InvalidDataException -ErrorId 'InvalidDataError' -ErrorMessage 'My error message'

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
        [System.String]
        $ErrorMessage
    )

    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidData
    $exception = New-Object `
        -TypeName System.InvalidOperationException `
        -ArgumentList $ErrorMessage
    $errorRecord = New-Object `
        -TypeName System.Management.Automation.ErrorRecord `
        -ArgumentList $exception, $ErrorId, $errorCategory, $null

    throw $errorRecord
}
