# ServiceNowAPI

## Requirements

```posh
Install-Script -Name Install-RequiredModule
```

## Building your module

1. run `Install-RequiredModule`

2. run `Build-Module .\Source`

3. compiled module appears in the `Output` folder

## Versioning

ModuleBuilder will automatically apply the next semver version
if you have installed [gitversion](https://gitversion.readthedocs.io/en/latest/).

To manually create a new version run `Build-Module .\Source -SemVer 0.0.2`

## Additional Information

https://github.com/PoshCode/ModuleBuilder
