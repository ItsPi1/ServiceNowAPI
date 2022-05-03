# Due to the importation of the module before every test code coverage is broken.
# Each individual function would need to be imported at the beginning of the test.
# Do not have the module imported into session before running the test. 
# https://stackoverflow.com/questions/46519096/invoke-pester-codecoverage-claims-0-code-coverage-when-testing-module-function
$configuration = @{
    Run = @{
        Path = "$PSScriptRoot"
    }
    CodeCoverage = @{
        Enabled = $false
        Path    = "$PSScriptRoot\..\Source\Private\*", "$PSScriptRoot\..\Source\Public\*"
    }
}
$config = New-PesterConfiguration -Hashtable $configuration
Invoke-Pester -Configuration $config