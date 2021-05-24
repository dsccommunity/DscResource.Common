
<#
    .SYNOPSIS
        Convert any object to hashtable.

    .DESCRIPTION
        This function is used to convert a psobject into a hashtable.

    .PARAMETER InputObject
        The object that should be convert to hashtable.

    .OUTPUTS
        Hashtable

    .EXAMPLE

    $Object = [pscustomobject]=@{
        FirstName = 'John'
        LastName = 'Smith'
    }

    Convert-ObjectToHashtable -InputObject $Object

    This creates a pscustomobject and converts its properties/values to Hashtable Key/Value.

    .EXAMPLE

    $ObjectArray = [pscustomobject]=@{
        FirstName = 'John'
        LastName = 'Smith'
    },[pscustomobject]=@{
        FirstName = 'Peter'
        LastName = 'Smith'
    }

    $ObjectArray | Convert-ObjectToHashtable

    This creates pscustomobjects and converts there properties/values to Hashtable Keys/Values through the pipeline.
#>
function Convert-ObjectToHashtable
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject
    )
    process {

        $hashResult = @{}
        foreach ($obj in $InputObject)
        {
            $obj.psobject.Properties | Foreach-Object {
                $hashResult[$_.Name] = $_.Value
            }

            return $hashResult
        }
    }
}
