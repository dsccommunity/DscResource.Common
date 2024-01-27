# Changelog for DscResource.Common

All notable changes to this project will be documented in this file.

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Get-PSModulePath`
  - Can now return the individual module path for different scopes when
    using the parameter `-Scope`. If no parameter is specified the command
    return the path for the scope CurrentUser.

### Fixed

- `Get-PSModulePath`
  - Was using the wrong path separator on Linux and macOS.

## [0.17.0] - 2024-01-23

### Added

- Tasks for automating documentation for the GitHub repository wiki ([issue #110](https://github.com/dsccommunity/DscResource.Common/issues/110)).
- `Set-PSModulePath`
  - A new parameters set takes two parameters `FromTarget` and `ToTarget`
    that can copy from omne target to the other ([issue #102](https://github.com/dsccommunity/DscResource.Common/issues/102)).
  - A new parameter `PassThru` that, if specified, returns the path that
    was set.
- `New-Exception`
  - New command that creates and returns an `[System.Exception]`.
- `New-ErrorRecord`
  - New command that creates and returns an `[System.Management.Automation.ErrorRecord]`
    ([issue #99](https://github.com/dsccommunity/DscResource.Common/issues/99)).
- `New-ArgumentException`
  - Now takes a parameter `PassThru` that returns the error record that was
    created (and does not throw).
- `New-InvalidOperationException`
  - Now takes a parameter `PassThru` that returns the error record that was
    created (and does not throw) ([issue #98](https://github.com/dsccommunity/DscResource.Common/issues/98)).
- `New-InvalidResultException`
  - Now takes a parameter `PassThru` that returns the error record that was
    created (and does not throw).
- `New-NotImplementedException`
  - Now takes a parameter `PassThru` that returns the error record that was
    created (and does not throw).
- `Compare-DscParameterState`
  - Add support for the type `[System.Collections.Specialized.OrderedDictionary]`
    passed to parameters `CurrentValues` and `DesiredValues` ([issue #57](https://github.com/dsccommunity/DscResource.Common/issues/57)).
  - Add support for `DesiredValues` (and `CurrentValues`) to pass a value,
    e.g a hashtable, that includes a property with the type `[System.Collections.Specialized.OrderedDictionary]`
    or an array of `[System.Collections.Specialized.OrderedDictionary]` ([issue #57](https://github.com/dsccommunity/DscResource.Common/issues/57)).

### Changed

- Updated the pipelines files for resolving dependencies.
- Command documentation was moved from README to GitHub repository wiki.
- Change the word cmdlet to command throughout in the documentation, code
  and localization strings.
- A meta task now removes the built module from the session if it is imported.
- Wiki source file HOME was modified to not link to README for help after
  command documentation now is in the wiki.
- `Get-LocalizedData`
  - Refactored to simplify execution and debugging. The command previously
    used a steppable pipeline (proxies `Import-LocalizedData`), that was
    removed since it was not possible to use the command in a pipeline.
    It just made it more complex and harder to debug. There are more
    debug messages added to hopefully simplify solving some hard to find
    edge cases bugs.
- `New-ArgumentException`
  - Now has a command alias `New-InvalidArgumentException` and the command
    was renamed to match the exception name.
  - Now uses the new command `New-ErrorRecord`.
- `New-InvalidDataException`
  - The parameter `Message` has a parameter alias `ErrorMessage` to make
    the command have the same parameter names as the other `New-*Exception`
    commands.
  - Now uses the new command `New-ErrorRecord`.
- `New-InvalidOperationException`
  - Now uses the new command `New-ErrorRecord`.
- `New-InvalidResultException`
  - Now uses the new command `New-ErrorRecord`.
- `New-NotImplementedException`
  - Now uses the new command `New-ErrorRecord`.
- `New-ObjectNotFoundException`
  - Now uses the new command `New-ErrorRecord`.

### Fixed

- `Assert-BoundParameter`
  - Fixed example in documentation that were referencing an invalid command name.
- `Get-LocalizedData`
  - One debug message was wrongly using a format operator ([issue #111](https://github.com/dsccommunity/DscResource.Common/issues/111).
- `New-ObjectNotFoundException`
  - Updated typo in comment-based help.

## [0.16.0] - 2023-04-10

### Added

- New public commands.
  - `Get-EnvironmentVariable` - Get a specific environment variable from a
    specific environment variable target.
  - `Get-PSModulePath` - Get the the PSModulePath from one or more environment
    variable targets - [Issue #103](https://github.com/dsccommunity/DscResource.Common/issues/103)

## [0.15.0] - 2023-04-06

### Added

- Added public function `Find-Certificate` that returns one or more
  certificates using certificate selector parameters - [Issue #100](https://github.com/dsccommunity/DscResource.Common/issues/100)
  - Related to [CertificateDsc Issue #272](https://github.com/dsccommunity/CertificateDsc/issues/272).

## [0.14.0] - 2022-12-31

### Added

- Added private function `Assert-RequiredCommandParameter` that throws an
  exception if a specified parameter is not assigned a value, and optionally
  throws only if a specific parameter is passed. - [Issue #92](https://github.com/dsccommunity/DscResource.Common/issues/92)
  - Related to SqlServerDsc [Issue #1796](https://github.com/dsccommunity/SqlServerDsc/issues/1796).
- Added public function `Test-AccountRequirePassword` that returns true or
  false whether an account need a password to be passed - [Issue #93](https://github.com/dsccommunity/DscResource.Common/issues/93)
  - Related to SqlServerDsc [Issue #1794](https://github.com/dsccommunity/SqlServerDsc/issues/1794).
- Added public command `Get-DscProperty` that returns a hashtable of available
  properties for a class-based resource. See comment-based help for more
  information.
- Added public command `Test-DscProperty` that returns a true or false
  whether a property exist in a class-based resource. See comment-based help
  for more information.
- Added private function `Test-DscPropertyIsAssigned` that returns a true
  or false whether a property in a class-based resource has a non-null value.

### Changed

- DscResource.Common
  - Updated Visual Studio Code project settings to configure testing for Pester 5.
- `Assert-BoundParameter`
  - Now has a new parameter set that calls `Assert-RequiredCommandParameter`
    which will throw an exception if a specified parameter is not assigned
    a value, and optionally throws only if a specific parameter is passed.

### Fixed

- Fixed unit tests for `Assert-ElevatedUser` and `Test-IsNumericType` so
  the public function is tested correctly using the exported function.
- Fixed unit tests to easier run test both from command line and inside
  Visual Studio Code.

## [0.13.1] - 2022-12-18

### Changed

- DscResource.Common
  - Now builds the module into a separate folder `output/builtModule`.

### Fixed

- `Test-IsNumericType`
  - Now handles arrays correctly.

## [0.13.0] - 2022-12-17

### Added

- Added public function `Test-IsNumericType` that returns whether the specified
  object is of a numeric type - [Issue #87](https://github.com/dsccommunity/DscResource.Common/issues/87)
  - Related to SqlServerDsc [Issue #1795](https://github.com/dsccommunity/SqlServerDsc/issues/1795).

### Changed

- `Assert-ElevatedUser`
  - Renamed the localized string key name and prepared the localized string
    file to be able to distinguish which key belong to which command.

## [0.12.0] - 2022-12-10

### Added

- Added public function `Assert-ElevatedUser` that asserts the user has elevated
  the PowerShell session. [Issue #82](https://github.com/dsccommunity/DscResource.Common/issues/82)
  - Related to SqlServerDsc [Issue #1797](https://github.com/dsccommunity/SqlServerDsc/issues/1797).

## [0.11.1] - 2022-08-18

### Changed

- DscResource.Common
  - updating the Get-LocalizedData to bypass Import-LocalizedData when in Globalization-Invariant mode.
    The command throws when running on an Invariant culture on Linux in the latest PS versions.

## [0.11.0] - 2022-08-01

### Changed

- DscResource.Common
  - Update pipeline files to the latest in Sampler.
    - Fix missing tasks module.
  - Update unit tests to import and remove the module being tested.

### Fixed

- Correction to `Compare-DscParameterState` returning false positive when parameter
  with an empty hashtable or CimInstance property is passed in `DesriedValues` - fixes
  [issue #65](https://github.com/dsccommunity/DscResource.Common/issues/65).
- Correction somes problems in `Compare-DscParameterState` - see [issue #70](https://github.com/dsccommunity/DscResource.Common/issues/70) :
  - When you use `-ReverseCheck`, this value is used in recursive call of
  `Test-DscParameterState` and `Compare-DscParameterState`, and that called
  another time the function.
  - When you use `-Properties` and `-ReverseCheck`, and you have an array in member,
  that return a wrong value, because the properties are set in recursive calls of
  `-ReverseCheck` to test the value of array.
  - When you use `-ReverseCheck` and, in the function `Test-DscCompareState`/`Compare-DscParameterState`
  are recursively called (like to test or compare value of array), `-ReverseCheck`
  value is removed from `$PSBoundParameters`. And the ReverseCheck isn't done.

## [0.10.3] - 2021-06-26

### Added

- Added cmdlet `ConvertFrom-DscResourceInstance` which can be used to convert any
  object to in another format. It accepts objects from pipeline. [issue #71](https://github.com/dsccommunity/DscResource.Common/issues/71).
- Now code coverage is uploaded to codecov.io.

### Changed

- Unit tests are now running using Pester 5 ([issue #40](https://github.com/dsccommunity/DscResource.Common/issues/40)).
- Excludes the PowerShell module script file _DscResource.Common.psm1_ located
  in folder _source_ from the HQRM testing.

## [0.10.2] - 2021-03-24

### Changed

- DscResource.Common
  - Renamed default branch to `main` - fixes [issue #62](https://github.com/dsccommunity/DscResource.Common/issues/62).
  - Changed to use the new GitHub deploy tasks.
- `Assert-Module`
  - Now it possible to forcibly import a module using `-ImportModule -Force`
  - It no longer outputs verbose messages that is normally generated when
    using `Get-Module -ListAvailable` if the module that is asserted is
    already in the session ([issue #66](https://github.com/dsccommunity/DscResource.Common/issues/66)).
- `Compare-DscParameterState`
  - Fix verbose message to only show when using parameter `IncludeInDesiredState`.
    Also made the verbose message more intuitive when the value being compared
    was a `[System.Boolean]`.

## [0.10.1] - 2020-12-25

### Added

- Added cmdlet `Get-ComputerName` which can be used to returns the computer
  name cross-plattform. The variable `$env:COMPUTERNAME` does not exist
  cross-platform which hinders development and testing on macOS and Linux.
  Instead this cmdlet can be used to get the computer name cross-plattform.

## [0.10.0] - 2020-11-18

### Added

- Added cmdlet `Compare-DscParameterState` - Could be used in
  Get-TargetResource function or Get() method in Class based Resources.
  It is based on the code of Test-DscParameterState function to get compliance
  between current and desired state of resources.
  The OutPut of Compare-DscParameterState is a collection psobject.
  The properties of psobject are Property,InDesiredState,ExpectedType,ActualType,
  ExpectedValue and ActualValue. The IncludeInDesiredState parameter must be use to
  add ExeptedValue and ActualValue.
- Added pester test to test the pscredential object with `Compare-DscParameterState`.

### Changed

- Cmdlet Test-DscResourceState is now calling Compare-DscParameterState. Possible breaking change.
- IncludeInDesiredState and IncludeValue parameters of Compare-DscParameterState
  are removed in splatting when Test-DscCompareState is called.

### Fix

- Fix git diff command in QA tests on Linux and MacOS.

## [0.9.3] - 2020-07-25

## Fixed

- Correction to `Test-DscParameterState` returning false positive when parameter
  with an empty array is passed in `DesriedValues` or `CurrentValues` - fixes
  [issue #53](https://github.com/dsccommunity/DscResource.Common/issues/53).

## [0.9.2] - 2020-07-22

### Added

- `Test-DscParameterState` can now handle scriptblocks. The parameter 'ValuesToCheck' was renamed to 'Properties' but an alias
  was added so it is not a braking change. The parameter 'ExcludeProperties' was added.
- Added a new test for the alias 'ValuesToCheck' pointing to 'Properties'.
- Added cmdlet `Compare-ResourcePropertyState` that also introduces a new
  design pattern to evaluate properties in both _Test_ and _Set_ - fixes
  [issue #47](https://github.com/dsccommunity/DscResource.Common/issues/47).

## Fixed

- `Get-LocalizedData`
  - Now correctly evaluates the default UI culture
    on non-English operating systems ([issue #50](https://github.com/dsccommunity/DscResource.Common/issues/50).
  - If the LCID 127 is found it will be skipped and instead use the default
    UI culture (which is `'en-US'` unless specified) ([issue #11](https://github.com/dsccommunity/DscResource.Common/issues/11).

## [0.9.1] - 2020-07-08

## Added

- Added cmdlet `New-InvalidDataException` - fixes [Issue #42](https://github.com/dsccommunity/DscResource.Common/issues/42).
- Added cmdlet `Set-DscMachineRebootRequired` - fixes [Issue #43](https://github.com/dsccommunity/DscResource.Common/issues/43).
- Pinned `Pester` module version to `4.10.1` to enable build until
  `v5.x` is ready for use.

## [0.9.0] - 2020-05-18

### Added

- Added cmdlet `Set-PSModulePath`.

## [0.8.0] - 2020-05-11

- Added a default value of `en-US` to the `DefaultUICulture` parameter of the `Get-LocalizedData` function
  [Issue #33](https://github.com/dsccommunity/DscResource.Common/issues/33).
- Fixing a problem with the latest ModuleBuild 1.7.0 that breaks the CI pipeline.

## [0.7.1] - 2020-05-02

### Fixed

- Add missing private function `Test-DscObjectHasProperty`.

## [0.7.0] - 2020-05-02

### Added

- Added the cmdlet `Assert-IPAddress`
- Added the cmdlet `ConvertTo-CimInstance`. _This cmdlet comes from NetworkingDsc._
- Added the cmdlet `ConvertTo-Hashtable`. _This cmdlet comes from NetworkingDsc._

### Changed

- Update the README.md with new cmdlet documentation format.
- Update to use HQRM tests from the DscResource.Test module.
- Update the repository to use the latest version of ModuleBuilder.
- Update to use the latest pipeline files.
- BREAKING CHANGE: Updated the cmdlet `Test-DscParameterState` to match
  the one in the module NetworkingDsc which have been extended with for
  example checking credentials and types. This might be a breaking change
  in certain scenarios, for example the type checking if on by default.
  _This change is required to be able to move the module NetworkingDsc_
  _to use this module._

## [0.6.0] - 2020-04-23

### Added

- Added the cmdlet `Assert-BoundParameter`. _This cmdlet comes from_
  _ComputerManagementDsc._
- Added the cmdlet `Get-TemporaryFolder`. _This cmdlet comes from_
  _SqlServerDsc._
- Added GitHub templates in the repository to help contributors.

### Changed

- Only run CI pipeline on branch `master` when there are changes to files
  inside the `source` folder.

### Fixed

- The regular expression for `minor-version-bump-message` in the file
  `GitVersion.yml` was changed to only raise minor version when the
  commit message contain the word `add`, `adds`, `minor`, `feature`,
  or `features`.
- Fixed the pipeline paths trigger.

## [0.5.0] - 2020-04-18

### Added

- Added `ImportModule` parameter to `Assert-Module` function.

### Changed

- Updated pipeline Windows VM image to windows-2019.

### Fixed

- Fixed the New-*Exception function unit tests to work correctly on PowerShell version 5, 6 and 7.

## [0.4.0] - 2020-03-09

### Added

- Added the function `Assert-Module`.

### Changed

- Updated the localized strings to have the unique id according to style
  guideline.

## [0.3.0] - 2020-02-15

### Added

- Added more function documentation to the README.md.
- Fix minor style issue in functions.
- Changed the VS Code project settings to trim trailing whitespace for
  markdown files too.
- Changed the VS Code project setting `pipelineIndentationStyle` to use
  the correct style.
- The deploy step is no longer run on forks.
- Azure Pipelines will no longer trigger on changes to just the CHANGELOG.md.
- Add section "How to implement" in the README.md.
- Added `Test-IsNanoServer` function - fixes [Issue #9](https://github.com/dsccommunity/DscResource.Common/issues/9).

## [0.2.0] - 2020-01-09

### Changed

- Updating pipeline files to the latest in the template.
- Updating and added section Code of conduct.
- Updating and added section contribution.
- Update README.md.
- The cmdlet `Get-LocalizedData` can now detect localized filenames
  that are using both the basename and the basename plus the suffix `strings`. E.g.
  - `MSFT_Cluster.psd1`
  - `MSFT_Cluster.strings.psd1`

## [0.1.1] - 2019-11-27

### Added

- New module based on the functions available in DscResource.Template
- Change the minimum requirement to PowerShell 4.0.

### Changed

- skip tests (it ...) using New-CimInstance when OS is not Windows (see issue #1)
- updating secrets and account used
