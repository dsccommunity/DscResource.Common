<#
    .SYNOPSIS
        Convert any object to hashtable.

    .DESCRIPTION
        This function is used to convert a PSObject into a hashtable.

    .PARAMETER InputObject
        The object that should be convert to hashtable.

    .PARAMETER OutputFormat
        Set the format you do want to convert the object. The default value is HashTable.
        It's the only value accepted at this time.

    .OUTPUTS
        System.Collections.Hashtable

    .EXAMPLE
        $object = [PSCustomObject] = @{
            FirstName = 'John'
            LastName = 'Smith'
        }
        ConvertFrom-DscResourceInstance -InputObject $object

        This creates a PSCustomObject and converts its properties and values to
        key/value pairs in a hashtable.

    .EXAMPLE
        $objectArray = [PSCustomObject] = @{
            FirstName = 'John'
            LastName = 'Smith'
        }, [PSCustomObject] = @{
            FirstName = 'Peter'
            LastName = 'Smith'
        }
        $objectArray | ConvertFrom-DscResourceInstance

        This creates an array of PSCustomObject and converts their properties and
        values to key/value pairs in a hashtable.
#>
function ConvertFrom-DscResourceInstance
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject,

        [Parameter()]
        [ValidateSet('HashTable')]
        [String]
        $OutputFormat = 'HashTable'

    )

    process
    {
        switch ($OutputFormat)
        {
            'HashTable'
            {
                $result = @{}

                foreach ($obj in $InputObject)
                {
                    $obj.PSObject.Properties | Foreach-Object {
                        $result[$_.Name] = $_.Value
                    }
                }
            }
        }

        return $result
    }
}
