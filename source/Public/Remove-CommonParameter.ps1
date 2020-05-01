<#
    .SYNOPSIS
        Removes common parameters from a hashtable.

    .DESCRIPTION
        This function serves the purpose of removing common parameters and option
        common parameters from a parameter hashtable.

    .PARAMETER Hashtable
        The parameter hashtable that should be pruned.
#>
function Remove-CommonParameter
{
    [OutputType([System.Collections.Hashtable])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Hashtable
    )

    $inputClone = $Hashtable.Clone()

    $commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
    $commonParameters += [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

    $Hashtable.Keys | Where-Object -FilterScript {
        $_ -in $commonParameters
    } | ForEach-Object -Process {
        $inputClone.Remove($_)
    }

    return $inputClone
}
