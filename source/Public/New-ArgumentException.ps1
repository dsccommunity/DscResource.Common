<#
    .SYNOPSIS
        Creates and throws or returns an invalid argument exception.

    .DESCRIPTION
        Creates and throws or returns an invalid argument exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown.

    .PARAMETER PassThru
        If specified, returns the error record instead of throwing it.

    .OUTPUTS
        None
        System.Management.Automation.ErrorRecord

    .EXAMPLE
        New-ArgumentException -ArgumentName 'Action' -Message 'My error message'

        Creates and throws an invalid argument exception for (parameter) 'Action'
        with the message 'My error message'.

    .EXAMPLE
        $errorRecord = New-ArgumentException -ArgumentName 'Action' -Message 'My error message' -PassThru

        Creates an invalid argument exception for (parameter) 'Action'
        with the message 'My error message' and returns the exception.
#>

function New-ArgumentException
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    [Alias('New-InvalidArgumentException')]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ArgumentName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    $argumentException = New-Object -TypeName 'ArgumentException' `
        -ArgumentList @($Message, $ArgumentName)

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @($argumentException, $ArgumentName, 'InvalidArgument', $null)
    }

    $errorRecord = New-Object @newObjectParameters

    if ($PassThru.IsPresent)
    {
        return $argumentException
    }
    else
    {
        throw $errorRecord
    }
}
