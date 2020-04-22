# DscResource.Common

[![Build Status](https://dev.azure.com/dsccommunity/DscResource.Common/_apis/build/status/dsccommunity.DscResource.Common?branchName=master)](https://dev.azure.com/dsccommunity/DscResource.Common/_build/latest?definitionId=4&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/DscResource.Common/4/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/DscResource.Common/4/master)](https://dsccommunity.visualstudio.com/DscResource.Common/_test/analytics?definitionId=4&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/DscResource.Common?label=DscResource.Common%20Preview)](https://www.powershellgallery.com/packages/DscResource.Common/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/DscResource.Common?label=DscResource.Common)](https://www.powershellgallery.com/packages/DscResource.Common/)

This module contains common functions that are used in DSC resources.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## How to implement

See the article [DscResource.Common functions in a DSC module](/blog/use-dscresource-common-functions-in-module/)
describing how to convert a DSC resource module to use DscResource.Common.

## Cmdlet

Refer to the comment-based help for more information about these helper
functions.

### `Assert-BoundParameter`

Asserts that a specified set of parameters are not passed together with another set of parameters.
There is no built in logic to validate against parameters sets for DSC
so this can be used instead to validate the parameters that were set in
the configuration.

This example throws an exception if `$PSBoundParameters` contains both
the parameters `Parameter1` and `Parameter2`

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

### `Assert-Module`

Assert if the specific module is available to be imported and optionally import the module.

```powershell
Assert-Module -ModuleName 'DhcpServer' -ImportModule
```

### `Get-LocalizedData`

Gets language-specific data into scripts and functions based on the UI culture
that is selected for the operating system. Similar to Import-LocalizedData, with
extra parameter 'DefaultUICulture'.

This should be used at the top of each resource PowerShell module script file
(.psm1).

```powershell
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
```

It will automatically look for a file in the folder for the current UI
culture, or default to the UI culture folder 'en-US'.

The localized strings file can be named either `<ScriptFileName>.psd1`,
e.g. `DSC_MyResource.psd1`, or suffixed with `strings`, e.g.
`DSC_MyResource.strings.psd1`.

Read more about localization in the section [Localization](https://dsccommunity.org/styleguidelines/localization/)
in the DSC Community style guideline.

### `Get-TemporaryFolder`

Returns the users temporary folder.

- Windows: C:\Users\username\AppData\Local\Temp\
- macOS: /var/folders/6x/thq2xce46bc84lr66fih2p5h0000gn/T
- Linux: /tmp

```powershell
Join-Path -Path (Get-TemporaryFolder) -ChildPath 'MyTempFile`
```

### `New-InvalidArgumentException`

Creates and throws an invalid argument exception.

```powershell
if ( -not $resultOfEvaluation )
{
    $errorMessage = `
        $script:localizedData.ActionCannotBeUsedInThisContextMessage `
            -f $Action, $Parameter

    New-InvalidArgumentException -ArgumentName 'Action' -Message $errorMessage
}
```

### `New-InvalidOperationException`

Creates and throws an invalid operation exception.

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

```powershell
if ($runFeature)
{
    $errorMessage = $script:localizedData.FeatureMissing -f $path
    New-NotImplementedException -Message $errorMessage -ErrorRecord $_
}
```

### `New-ObjectNotFoundException`

Creates and throws an object not found exception.

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

### `Test-DscParameterState`

This function is used to compare current and desired values for any DSC resource.

### `Test-IsNanoServer`

This function tests if the current OS is a Nano server.
