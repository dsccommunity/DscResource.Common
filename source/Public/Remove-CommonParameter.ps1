<#
    .SYNOPSIS
        Removes common parameters from a hashtable.

    .DESCRIPTION
        This function serves the purpose of removing common parameters and option
        common parameters from a parameter hashtable.

    .OUTPUTS
        System.Collections.Hashtable

    .PARAMETER Hashtable
        The parameter hashtable that should be pruned.

    .EXAMPLE
        Remove-CommonParameter -Hashtable $PSBoundParameters

        Returns a new hashtable without the common and optional common parameters.
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

    $commonParameters = [System.Collections.Generic.HashSet[System.String]]::new(
        [System.String[]](
            [System.Management.Automation.PSCmdlet]::CommonParameters +
            [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
        ),
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($key in $Hashtable.Keys)
    {
        if ($commonParameters.Contains($key))
        {
            $null = $inputClone.Remove($key)
        }
    }

    return $inputClone
}
