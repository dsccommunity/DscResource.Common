<#
    .SYNOPSIS
        Creates and throws an invalid data exception.

    .DESCRIPTION
        Creates and throws an invalid data exception.

    .PARAMETER ErrorId
        The error Id to assign to the exception.

    .PARAMETER ErrorMessage
        The error message to assign to the exception.

    .EXAMPLE
        if ( -not $resultOfEvaluation )
        {
            $errorMessage = $script:localizedData.InvalidData -f $Action

            New-InvalidDataException -ErrorId 'InvalidDataError' -ErrorMessage $errorMessage
        }
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
