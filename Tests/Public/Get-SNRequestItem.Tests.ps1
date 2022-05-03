#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "Get-SNRequestItem" {
    Context "Parameters" {
        BeforeAll {
            $commandInfo = Get-Command Get-SNRequestItem
        }
        It 'Has a mandatory RequestItemID parameter' {
            $requestItemID = $commandInfo.Parameters['RequestItemID']
            $requestItemID | Should -Not -BeNullOrEmpty
            $requestItemID.ParameterType | Should -Be ([string])
            $requestItemID.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $requestItemID.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
            $requestItemID.Attributes.Where{ $_ -is [ValidateScript] }.ScriptBlock | Should -Not -BeNullOrEmpty # Do you have a better way of testing ValidateScript()?
        }

        It 'Has a mandatory APIMSubscriptionKey parameter' {
            $APIMSubscriptionKey = $commandInfo.Parameters['APIMSubscriptionKey']
            $APIMSubscriptionKey | Should -Not -BeNullOrEmpty
            $APIMSubscriptionKey.ParameterType | Should -Be ([string])
            $APIMSubscriptionKey.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $APIMSubscriptionKey.Attributes.Where{ $_ -is [Parameter] }.ParameterSetName | Should -Contain "__AllParameterSets"
            $APIMSubscriptionKey.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Test Validate Script for RequestItemID parameter" {
        BeforeAll {
            InModuleScope ServiceNowAPI {
                Mock Invoke-SNMethod { return $null }
            }
        }

        It 'Should accept strings that start with RITM' {
            # Input to '-Throw' and '-Not -Throw' must be enclosed in curly braces.
            { Get-SNRequestItem -RequestItemID 'RITMXXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { Get-SNRequestItem -RequestItemID 'XRITMXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { Get-SNRequestItem -RequestItemID 'ABCXXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }

        It 'Should accept strings that are 32 characters long and do not begin with RITM' {
            $stringValid = "A" * 32
            $stringInvalid1 = "A" * 31
            $stringInValid2 = "A" * 33
            { Get-SNRequestItem -RequestItemID $stringValid -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { Get-SNRequestItem -RequestItemID $stringInValid1 -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { Get-SNRequestItem -RequestItemID $stringInValid2 -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }
    }
}