
<#
    .SYNOPSIS
        Convert any object to hashtable.

    .DESCRIPTION
        This function is used to convert a psobject into a hashtable.

    .PARAMETER InputObject
        The object that should be convert to hashtable.

    .PARAMETER OutPutFormat
        Set the format you do want to convert the object. The default value is HashTable.
        It's the only value accepted at this time.

    .OUTPUTS
        Hashtable

    .EXAMPLE

    $Object = [pscustomobject]=@{
        FirstName = 'John'
        LastName = 'Smith'
    }

    ConvertFrom-DscResourceInstance -InputObject $Object

    This creates a pscustomobject and converts its properties/values to Hashtable Key/Value.

    .EXAMPLE

    $ObjectArray = [pscustomobject]=@{
        FirstName = 'John'
        LastName = 'Smith'
    },[pscustomobject]=@{
        FirstName = 'Peter'
        LastName = 'Smith'
    }

    $ObjectArray | ConvertFrom-DscResourceInstance

    This creates pscustomobjects and converts there properties/values to Hashtable Keys/Values through the pipeline.
#>
function ConvertFrom-DscResourceInstance
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject,

        [Parameter()]
        [ValidateSet('HashTable')]
        [String]
        $OutPutFormat = 'HashTable'

    )
    process {

        switch ($OutPutFormat)
        {
            'HashTable'
            {
                $Result = @{}
                foreach ($obj in $InputObject)
                {
                    $obj.psobject.Properties | Foreach-Object {
                        $Result[$_.Name] = $_.Value
                    }
                }
            }
        }

        return $Result
    }
}
