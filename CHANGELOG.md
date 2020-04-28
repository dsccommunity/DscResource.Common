# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Update the README.md with new cmdlet documentation format.

### Fixed

- The code in the unit tests for `Test-DscParameterState` is now closer
  following the style guideline.

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
