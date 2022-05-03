#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "Get-SNRequest" {
    Context "Parameters" {
        BeforeAll {
            $commandInfo = Get-Command Get-SNRequest
        }
        It 'Has a mandatory RequestID parameter' {
            $requestID = $commandInfo.Parameters['RequestID']
            $requestID | Should -Not -BeNullOrEmpty
            $requestID.ParameterType | Should -Be ([string])
            $requestID.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $requestID.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
            $requestID.Attributes.Where{ $_ -is [ValidateScript] }.ScriptBlock | Should -Not -BeNullOrEmpty # Do you have a better way of testing ValidateScript()?
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

    Context "Test Validate Script for RequestID parameter" {
        BeforeAll {
            InModuleScope ServiceNowAPI {
                Mock Invoke-SNMethod { return $null }
            }
        }

        It 'Should accept strings that start with REQ' {
            # Input to '-Throw' and '-Not -Throw' must be enclosed in curly braces.
            { Get-SNRequest -RequestID 'REQXXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { Get-SNRequest -RequestID 'XREQXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { Get-SNRequest -RequestID 'ABCXXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }

        It 'Should accept strings that are 32 characters long and do not begin with REQ' {
            $stringValid = "A" * 32
            $stringInvalid1 = "A" * 31
            $stringInValid2 = "A" * 33
            { Get-SNRequest -RequestID $stringValid -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { Get-SNRequest -RequestID $stringInValid1 -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { Get-SNRequest -RequestID $stringInValid2 -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }
    }
}