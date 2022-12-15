# DscResource.Common

[![Build Status](https://dev.azure.com/dsccommunity/DscResource.Common/_apis/build/status/dsccommunity.DscResource.Common?branchName=main)](https://dev.azure.com/dsccommunity/DscResource.Common/_build/latest?definitionId=4&branchName=main)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/DscResource.Common/4/main)
[![codecov](https://codecov.io/gh/dsccommunity/DscResource.Common/branch/main/graph/badge.svg)](https://codecov.io/gh/dsccommunity/DscResource.Common)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/DscResource.Common/4/main)](https://dsccommunity.visualstudio.com/DscResource.Common/_test/analytics?definitionId=4&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/DscResource.Common?label=DscResource.Common%20Preview)](https://www.powershellgallery.com/packages/DscResource.Common/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/DscResource.Common?label=DscResource.Common)](https://www.powershellgallery.com/packages/DscResource.Common/)

This module contains common functions that are used in DSC resources.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `main` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## How to implement

See the article [DscResource.Common functions in a DSC module](https://dsccommunity.org/blog/use-dscresource-common-functions-in-module/)
describing how to convert a DSC resource module to use DscResource.Common.

## Cmdlets
<!-- markdownlint-disable MD036 - Emphasis used instead of a heading -->

Refer to the comment-based help for more information about these helper
functions.

### `Assert-BoundParameter`

Asserts that a specified set of parameters are not passed together with
another set of parameters.
There is no built in logic to validate against parameters sets for DSC
so this can be used instead to validate the parameters that were set in
the configuration.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Assert-BoundParameter [-BoundParameterList] <hashtable> [-MutuallyExclusiveList1] <string[]>
 [-MutuallyExclusiveList2] <string[]> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

None.

#### Example

```powershell
$assertBoundParameterParameters = @{
    BoundParameterList = $PSBoundParameters
    MutuallyExclusiveList1 = @(
        'Parameter1'
    )
    MutuallyExclusiveList2 = @(
        'Parameter2'
    )
}

Assert-BoundParameter @assertBoundParameterParameters
```

This example throws an exception if `$PSBoundParameters` contains both
the parameters `Parameter1` and `Parameter2`.

### `Assert-ElevatedUser`

Assert that the user has elevated the PowerShell session.

`Assert-ElevatedUser` will throw a statement-terminating error if the 
script is not run from an elevated session.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Assert-ElevatedUser [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

None.

#### Example

```powershell
`Assert-ElevatedUser -ErrorAction 'Stop'`
```

This example stops the entire script if it is not run from an 
elevated PowerShell session.

### `Assert-IPAddress`

Asserts if the IP Address is valid and optionally validates
the IP Address against an Address Family

#### Syntax

```plaintext
Assert-IPAddress [-Address] <string> [[-AddressFamily] <string>] [<CommonParameters>]
```

#### Outputs

None.

#### Example

```powershell
Assert-IPAddress -Address '127.0.0.1'
```

This will assert that the supplied address is a valid IPv4 address.
If it is not an exception will be thrown.

```powershell
Assert-IPAddress -Address 'fe80:ab04:30F5:002b::1'
```

This will assert that the supplied address is a valid IPv6 address.
If it is not an exception will be thrown.

```powershell
Assert-IPAddress -Address 'fe80:ab04:30F5:002b::1' -AddressFamily 'IPv6'
```

This will assert that address is valid and that it matches the
supplied address family. If the supplied address family does not match
the address an exception will be thrown.

### `Assert-Module`

Assert if the specific module is available to be imported and optionally
import the module.

#### Syntax

```plaintext
Assert-Module [-ModuleName] <string> [-ImportModule] [-Force] [<CommonParameters>]
```

#### Outputs

None.

#### Example

```powershell
Assert-Module -ModuleName 'DhcpServer'
```

This will assert that the module DhcpServer is available. If it is not
an exception will be thrown.

```powershell
Assert-Module -ModuleName 'DhcpServer' -ImportModule
```

This will assert that the module DhcpServer is available and that it has
been imported into the session. If the module is not available an exception
will be thrown.

```powershell
Assert-Module -ModuleName 'DhcpServer' -ImportModule -Force
```

This will assert that the module DhcpServer is available and it will be
forcibly imported into the session (even if it was already in the session).
If the module is not available an exception will be thrown.

### `Compare-DscParameterState`

Compare current against desired property state for any DSC resource and return
a collection psobject with the metadata from the comparison.

The content of the function `Test-DscParameterState` has been extracted and now
`Test-DscParameterState` is just calling `Compare-DscParameterState`.
This function can be used in a DSC resource from the _Get_ function/method.

#### Syntax

```plaintext
Compare-DscParameterState [-CurrentValues] <Object> [-DesiredValues] <Object>
[[-Properties]  <string[]>] [[-ExcludeProperties] <string[]>] [-TurnOffTypeChecking]
 [-ReverseCheck] [-SortArrayValues] [-IncludeInDesiredState] [-IncludeValue] [<CommonParameters>]
```

#### Outputs

Returns an array containing a psobject with metadata for each property
that was evaluated.

Metadata Name | Type | Description
--- | --- | ---
Property | `[System.String]` | The name of the property that was evaluated
InDesiredState | `[System.Boolean]` | Returns `$true` if the expected and actual value was equal.
ExpectedType | `[System.String]` | Return the type of desired object.
ActualType | `[System.String]` | Return the type of current object.
ExpectedValue | `[System.PsObject]` | Return the value of expected object.
ActualValue | `[System.PsObject]` | Return the value of current object.

#### Example

##### Example 1
```powershell
$currentValues = @{
    String = 'This is a string'
    Int = 1
    Bool = $true
}

$desiredValues = @{
    String = 'This is a string'
    Int = 99
}

Compare-DscParameterState -CurrentValues $currentValues -DesiredValues $desiredValues
#result
Name                           Value
----                           -----
Property                       Int
InDesiredState                 False
ExpectedType                   System.Int32
ActualType                     System.Int32
```

The function Compare-DscParameterState compare the value of each hashtable based
on the keys present in $desiredValues hashtable. The result indicates that Int
property is not in the desired state.
No information about Bool property, because it is not in $desiredValues hashtable.

##### Example 2

```powershell
$currentValues = @{
    String = 'This is a string'
    Int = 1
    Bool = $true
}

$desiredValues = @{
    String = 'This is a string'
    Int = 99
    Bool = $false
}

$excludeProperties = @('Bool')

Compare-DscParameterState `
    -CurrentValues $currentValues `
    -DesiredValues $desiredValues `
    -ExcludeProperties $ExcludeProperties
#result
Name                           Value
----                           -----
Property                       Int
InDesiredState                 False
ExpectedType                   System.Int32
ActualType                     System.Int32
```

The function Compare-DscParameterState compare the value of each hashtable based
on the keys present in $desiredValues hashtable and without those in $excludeProperties.
The result indicates that Int property is not in the desired state.
No information about Bool property, because it is in $excludeProperties.

##### Example 3

```powershell
$serviceParameters = @{
    Name     = $Name
}

$returnValue = Compare-DscParameterState `
    -CurrentValues (Get-Service @serviceParameters) `
    -DesiredValues $PSBoundParameters `
    -Properties @(
        'Name'
        'Status'
        'StartType'
    )
```

This compares the values in the current state against the desires state.
The command Get-Service is called using just the required parameters
to get the values in the current state. The parameter 'Properties'
is used to specify the properties 'Name','Status' and
'StartType' for the comparison.

### `Compare-ResourcePropertyState`

Compare current and desired property state for any DSC resource and return
a hashtable with the metadata from the comparison.

This introduces a new design pattern that is used to evaluate current and
desired state in a DSC resource. This cmdlet is meant to be used in a DSC
resource from both _Test_ and _Set_. The evaluation is made in _Set_
to make sure to only change the properties that are not in the desired state.
Properties that are in the desired state should not be changed again. This
design pattern also handles when the cmdlet `Invoke-DscResource` is called
with the method `Set`, which with this design pattern will evaluate the
properties correctly.

See the other design pattern that uses the cmdlet [`Test-DscParameterState`](#test-dscparameterstate)

#### Syntax

```plaintext
Compare-ResourcePropertyState [-CurrentValues] <hashtable> [-DesiredValues] <hashtable>
 [[-Properties] <string[]>] [[-IgnoreProperties] <string[]>]
 [[-CimInstanceKeyProperties] <hashtable>] [<CommonParameters>]
```

#### Outputs

Returns an array containing a hashtable with metadata for each property
that was evaluated.

Metadata Name | Type | Description
--- | --- | ---
ParameterName | `[System.String]` | The name of the property that was evaluated
Expected | The type of the property | The desired value for the property
Actual | The type of the property | The actual current value for the property
InDesiredState | `[System.Boolean]` | Returns `$true` if the expected and actual value was equal.

#### Example

##### Example 1

```powershell
$compareTargetResourceStateParameters = @{
    CurrentValues = (Get-TargetResource $PSBoundParameters)
    DesiredValues = $PSBoundParameters
}

$propertyState = Compare-ResourcePropertyState @compareTargetResourceStateParameters

$propertiesNotInDesiredState = $propertyState.Where({ -not $_.InDesiredState })
```

This example calls Compare-ResourcePropertyState with the current state
and the desired state and returns a hashtable array of all the properties
that was evaluated based on the properties pass in the parameter DesiredValues.
Finally it sets a parameter `$propertiesNotInDesiredState` that contain
an array with all properties not in desired state.

##### Example 2

```powershell
$compareTargetResourceStateParameters = @{
    CurrentValues = (Get-TargetResource $PSBoundParameters)
    DesiredValues = $PSBoundParameters
    Properties    = @(
        'Property1'
    )
}

$propertyState = Compare-ResourcePropertyState @compareTargetResourceStateParameters

$false -in $propertyState.InDesiredState
```

This example calls Compare-ResourcePropertyState with the current state
and the desired state and returns a hashtable array with just the property
`Property1` as that was the only property that was to be evaluated.
Finally it checks if `$false` is present in the array property `InDesiredState`.

##### Example 3

```powershell
$compareTargetResourceStateParameters = @{
    CurrentValues    = (Get-TargetResource $PSBoundParameters)
    DesiredValues    = $PSBoundParameters
    IgnoreProperties = @(
        'Property1'
    )
}

$propertyState = Compare-ResourcePropertyState @compareTargetResourceStateParameters
```

This example calls Compare-ResourcePropertyState with the current state
and the desired state and returns a hashtable array of all the properties
except the property `Property1`.

##### Example 4

```powershell
$compareTargetResourceStateParameters = @{
    CurrentValues    = (Get-TargetResource $PSBoundParameters)
    DesiredValues    = $PSBoundParameters
    CimInstanceKeyProperties = @{
        ResourceProperty1 = @(
            'CimProperty1'
        )
    }
}

$propertyState = Compare-ResourcePropertyState @compareTargetResourceStateParameters
```

This example calls Compare-ResourcePropertyState with the current state
and the desired state and have a property `ResourceProperty1` who's value
is an  array of embedded CIM instances. The key property for the CIM instances
are `CimProperty1`. The CIM instance key property `CimProperty1` is used
to get the unique CIM instance object to compare against from both the current
state and the desired state.

### `ConvertTo-CimInstance`

This function is used to convert a hashtable into MSFT_KeyValuePair objects.
These are stored as an CimInstance array. DSC cannot handle hashtables but
CimInstances arrays storing MSFT_KeyValuePair.

#### Syntax

```plaintext
ConvertTo-CimInstance -Hashtable <hashtable> [<CommonParameters>]
```

### Outputs

**System.Object[]**

### Example

```powershell
ConvertTo-CimInstance -Hashtable @{
    String = 'a string'
    Bool   = $true
    Int    = 99
    Array  = 'a, b, c'
}
```

This example returns an CimInstance with the provided hashtable values.

### `ConvertTo-HashTable`

This function is used to convert a CimInstance array containing
MSFT_KeyValuePair objects into a hashtable.

#### Syntax

```plaintext
ConvertTo-HashTable -CimInstance <Microsoft.Management.Infrastructure.CimInstance[]>
 [<CommonParameters>]
```

### Outputs

**System.Collections.Hashtable**

### Example

```powershell
$newInstanceParameters = @{
    ClassName = 'MSFT_KeyValuePair'
    Namespace = 'root/microsoft/Windows/DesiredStateConfiguration'
    ClientOnly = $true
}

$cimInstance = [Microsoft.Management.Infrastructure.CimInstance[]] (
    (New-CimInstance @newInstanceParameters -Property @{
        Key   = 'FirstName'
        Value = 'John'
    }),

    (New-CimInstance @newInstanceParameters -Property @{
        Key   = 'LastName'
        Value = 'Smith'
    })
)

ConvertTo-HashTable -CimInstance $cimInstance
```

This creates a array om CimInstances of the class name MSFT_KeyValuePair
and passes it to ConvertTo-HashTable which returns a hashtable.

### `Get-ComputerName`

Returns the computer name cross-plattform. The variable `$env:COMPUTERNAME`
does not exist cross-platform which hinders development and testing on
macOS and Linux. Instead this cmdlet can be used to get the computer name
cross-plattform.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-ComputerName [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

**System.String**

#### Notes

None.

#### Example

```powershell
$computerName = Get-ComputerName
```

### `Get-LocalizedData`

Gets language-specific data into scripts and functions based on the UI culture
that is selected for the operating system. Similar to Import-LocalizedData, with
extra parameter 'DefaultUICulture'.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-LocalizedData [[-BindingVariable] <string>] [[-DefaultUICulture] <string>] [-BaseDirectory <string>]
 [-FileName <string>] [-SupportedCommand <string[]>] [<CommonParameters>]

Get-LocalizedData [[-BindingVariable] <string>] [[-UICulture] <string>] [-BaseDirectory <string>]
 [-FileName <string>] [-SupportedCommand <string[]>] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

**System.Collections.Hashtable**

Optionally the `Get-LocalizedData` saves the hash table in the variable
that is specified by the value of the `BindingVariable` parameter.

#### Notes

This should preferably be used at the top of each resource PowerShell module
script file (.psm1).

It will automatically look for a file in the folder for the current UI
culture, or default to the UI culture folder 'en-US'.

The localized strings file can be named either `<ScriptFileName>.psd1`,
e.g. `DSC_MyResource.psd1`, or suffixed with `strings`, e.g.
`DSC_MyResource.strings.psd1`.

Read more about localization in the section [Localization](https://dsccommunity.org/styleguidelines/localization/)
in the DSC Community style guideline.

#### Example

```powershell
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
```

### `Get-TemporaryFolder`

Returns the path of the current user's temporary folder.

#### Syntax

```plaintext
Get-TemporaryFolder [<CommonParameters>]
```

#### Outputs

**System.String**

#### Notes

Examples of what the cmdlet returns:

- Windows: C:\Users\username\AppData\Local\Temp\
- macOS: /var/folders/6x/thq2xce46bc84lr66fih2p5h0000gn/T/
- Linux: /tmp/

#### Example

```powershell
Join-Path -Path (Get-TemporaryFolder) -ChildPath 'MyTempFile`
```

### `New-InvalidArgumentException`

Creates and throws an invalid argument exception.

#### Syntax

```plaintext
New-InvalidArgumentException [-Message] <string> [-ArgumentName] <string> [<CommonParameters>]
```

### Outputs

None.

### Example

```powershell
if ( -not $resultOfEvaluation )
{
    $errorMessage = `
        $script:localizedData.ActionCannotBeUsedInThisContextMessage `
            -f $Action, $Parameter

    New-InvalidArgumentException -ArgumentName 'Action' -Message $errorMessage
}
```

### `New-InvalidDataException`

Creates and throws an invalid data exception.

#### Syntax

```plaintext
New-InvalidDataException [-ErrorId] <string> [-ErrorMessage] <string> [<CommonParameters>]
```

### Outputs

None.

### Example

```powershell
if ( -not $resultOfEvaluation )
{
    $errorMessage = $script:localizedData.InvalidData -f $Action

    New-InvalidDataException -ErrorId 'InvalidDataError' -ErrorMessage $errorMessage
}
```

### `New-InvalidOperationException`

Creates and throws an invalid operation exception.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
New-InvalidOperationException [-Message] <string> [[-ErrorRecord] <ErrorRecord>] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

### Outputs

None.

### Example

```powershell
try
{
    Start-Process @startProcessArguments
}
catch
{
    $errorMessage = $script:localizedData.InstallationFailedMessage -f $Path, $processId
    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
}
```

### `New-InvalidResultException`

Creates and throws an invalid result exception.

#### Syntax

```plaintext
New-InvalidResultException [-Message] <string> [[-ErrorRecord] <ErrorRecord>] [<CommonParameters>]
```

### Outputs

None.

### Example

```powershell
try
{
    $numberOfObjects = Get-ChildItem -Path $path
    if ($numberOfObjects -eq 0)
    {
        throw 'To few files.'
    }
}
catch
{
    $errorMessage = $script:localizedData.TooFewFilesMessage -f $path
    New-InvalidResultException -Message $errorMessage -ErrorRecord $_
}

```

### `New-NotImplementedException`

Creates and throws an not implemented exception.

#### Syntax

```plaintext
New-NotImplementedException [-Message] <string> [[-ErrorRecord] <ErrorRecord>] [<CommonParameters>]
```

### Outputs

None.

### Example

```powershell
if ($runFeature)
{
    $errorMessage = $script:localizedData.FeatureMissing -f $path
    New-NotImplementedException -Message $errorMessage -ErrorRecord $_
}
```

### `New-ObjectNotFoundException`

Creates and throws an object not found exception.

#### Syntax

```plaintext
New-ObjectNotFoundException [-Message] <String> [[-ErrorRecord] <ErrorRecord>] [<CommonParameters>]
```

### Outputs

None.

### Example

```powershell
try
{
    Get-ChildItem -Path $path
}
catch
{
    $errorMessage = $script:localizedData.PathNotFoundMessage -f $path
    New-ObjectNotFoundException -Message $errorMessage -ErrorRecord $_
}
```

### `Remove-CommonParameter`

This function serves the purpose of removing common parameters and option
common parameters from a parameter hashtable.

#### Syntax

```plaintext
Remove-CommonParameter [-Hashtable] <hashtable> [<CommonParameters>]
```

### Outputs

**System.Collections.Hashtable**

### Example

```powershell
Remove-CommonParameter -Hashtable $PSBoundParameters
```

Returns a new hashtable without the common and optional common parameters.

### `Set-DscMachineRebootRequired`

Set the DSC reboot required status variable.

#### Syntax

```plaintext
Set-DscMachineRebootRequired [<CommonParameters>]
```

### Outputs

None.

### Example

```powershell
Set-DscMachineRebootRequired
```

Sets the $global:DSCMachineStatus variable to 1.

### `Set-PSModulePath`

This is a wrapper to set environment variable PSModulePath in the current
session or machine wide.

#### Syntax

```plaintext
Set-PSModulePath [-Path] <String> [-Machine] [<CommonParameters>]
```

### Outputs

None.

### Example

```powershell
Set-PSModulePath -Path '<Path 1>;<Path 2>'
```

Sets the session environment variable `PSModulePath` to the specified path
or paths (separated with semi-colons).

```powershell
Set-PSModulePath -Path '<Path 1>;<Path 2>' -Machine
```

Sets the machine environment variable `PSModulePath` to the specified path
or paths (separated with semi-colons).

### `Test-DscParameterState`

This function is used to compare the values in the current state against
the desired values for any DSC resource.

This cmdlet was designed to be used in a DSC resource from only _Test_.
The design pattern that uses the cmdlet `Test-DscParameterState` assumes that
LCM is used which always calls _Test_ before _Set_, or that there never
is a need to evaluate the state in _Set_.

A new design pattern was introduces that uses the cmdlet [`Compare-ResourcePropertyState`](#compare-resourcepropertystate)

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Test-DscParameterState [-CurrentValues] <Object> [-DesiredValues] <Object>
  [-Properties] <string[]> [[-ExcludeProperties] <string[]>]
  [-TurnOffTypeChecking] [-ReverseCheck] [-SortArrayValues]
  [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

**System.Boolean**

#### Example

##### Example 1

<!-- markdownlint-disable MD013 - Line length -->
```powershell
$currentState = Get-TargetResource @PSBoundParameters

$returnValue = Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters
```
<!-- markdownlint-enable MD013 - Line length -->

The function `Get-TargetResource` is called first using all bound parameters
to get the values in the current state. The result is then compared to the
desired state by calling `Test-DscParameterState`.

##### Example 2

```powershell
$getTargetResourceParameters = @{
    ServerName     = $ServerName
    InstanceName   = $InstanceName
    Name           = $Name
}

$returnValue = Test-DscParameterState `
    -CurrentValues (Get-TargetResource @getTargetResourceParameters) `
    -DesiredValues $PSBoundParameters `
    -ExcludeProperties @(
        'FailsafeOperator'
        'NotificationMethod'
    )
```

##### Example 3

```powershell
$getTargetResourceParameters = @{
    ServerName     = $ServerName
    InstanceName   = $InstanceName
    Name           = $Name
}

$returnValue = Test-DscParameterState `
    -CurrentValues (Get-TargetResource @getTargetResourceParameters) `
    -DesiredValues $PSBoundParameters `
    -Properties ServerName, Name
```

This compares the values in the current state against the desires state.
The function `Get-TargetResource` is called using just the required parameters
to get the values in the current state.

### `Test-IsNanoServer`

This function tests if the current OS is a Nano server.

#### Syntax

```plaintext
Test-IsNanoServer [<CommonParameters>]
```

#### Outputs

**System.Boolean**

#### Example

```powershell
if ((Test-IsNanoServer)) {
    'Nano server'
}
```

### `Test-IsNumericType`

Returns whether the specified object is of a numeric type:
- [System.Byte]
- [System.Int16]
- [System.Int32]
- [System.Int64]
- [System.SByte]
- [System.UInt16]
- [System.UInt32]
- [System.UInt64]
- [System.Decimal]
- [System.Double]
- [System.Single]

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Test-IsNumericType [[-Object] <Object>] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

**System.Boolean**

#### Example

```PowerShell
Test-IsNumericType -Object ([System.UInt32] 3)
```
```PowerShell
([System.String] 'a') | Test-IsNumericType
```
<!-- markdownlint-enable MD036 - Emphasis used instead of a heading -->
