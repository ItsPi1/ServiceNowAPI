#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "Get-SNRequestTask" {
    Context "Parameters" {
        BeforeAll {
            $commandInfo = Get-Command Get-SNRequestTask
        }
        It 'Has a mandatory RequestTaskID parameter' {
            $requestTaskID = $commandInfo.Parameters['RequestTaskID']
            $requestTaskID | Should -Not -BeNullOrEmpty
            $requestTaskID.ParameterType | Should -Be ([string])
            $requestTaskID.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $requestTaskID.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
            $requestTaskID.Attributes.Where{ $_ -is [ValidateScript] }.ScriptBlock | Should -Not -BeNullOrEmpty # Do you have a better way of testing ValidateScript()?
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

    Context "Test Validate Script for RequestTaskID parameter" {
        BeforeAll {
            InModuleScope ServiceNowAPI {
                Mock Invoke-SNMethod { return $null }
            }
        }

        It 'Should accept strings that start with SCTASK' {
            # Input to '-Throw' and '-Not -Throw' must be enclosed in curly braces.
            { Get-SNRequestTask -RequestTaskID 'SCTASKXXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { Get-SNRequestTask -RequestTaskID 'XSCTASKXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { Get-SNRequestTask -RequestTaskID 'ABCXXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }

        It 'Should accept strings that are 32 characters long and do not begin with SCTASK' {
            $stringValid = "A" * 32
            $stringInvalid1 = "A" * 31
            $stringInValid2 = "A" * 33
            { Get-SNRequestTask -RequestTaskID $stringValid -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { Get-SNRequestTask -RequestTaskID $stringInValid1 -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { Get-SNRequestTask -RequestTaskID $stringInValid2 -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }
    }
}