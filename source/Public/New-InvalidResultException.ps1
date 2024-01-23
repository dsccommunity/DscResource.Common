<#
    .SYNOPSIS
        Creates and throws an invalid result exception.

    .DESCRIPTION
        Creates and throws an invalid result exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.

    .OUTPUTS
        None

    .EXAMPLE
        $numberOfObjects = Get-ChildItem -Path $path
        if ($numberOfObjects -eq 0)
        {
            New-InvalidResultException -Message 'To few files'
        }

        Creates and throws an invalid result exception with the message 'To few files'

    .EXAMPLE
        try
        {
            $numberOfObjects = Get-ChildItem -Path $path
        }
        catch
        {
            New-InvalidResultException -Message 'Missing files' -ErrorRecord $_
        }

        Creates and throws an invalid result exception with the message 'Missing files'
        and includes the exception that caused this terminating error.
#>
function New-InvalidResultException
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    $exception = New-Exception @PSBoundParameters

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $exception.ToString(),
            'MachineStateIncorrect',
            'InvalidResult',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}
