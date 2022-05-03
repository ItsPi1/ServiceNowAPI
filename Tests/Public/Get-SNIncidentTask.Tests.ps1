#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "Get-SNIncidentTask" {
    Context "Parameters" {
        BeforeAll {
            $commandInfo = Get-Command Get-SNIncidentTask
        }
        It 'Has a mandatory IncidentTaskID parameter' {
            $incidentTaskID = $commandInfo.Parameters['IncidentTaskID']
            $incidentTaskID | Should -Not -BeNullOrEmpty
            $incidentTaskID.ParameterType | Should -Be ([string])
            $incidentTaskID.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $incidentTaskID.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
            $incidentTaskID.Attributes.Where{ $_ -is [ValidateScript] }.ScriptBlock | Should -Not -BeNullOrEmpty # Do you have a better way of testing ValidateScript()?
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

    Context "Test Validate Script for IncidentTaskID parameter" {
        BeforeAll {
            InModuleScope ServiceNowAPI {
                Mock Invoke-SNMethod { return $null }
            }
        }

        It 'Should accept strings that start with TASK' {
            # Input to '-Throw' and '-Not -Throw' must be enclosed in curly braces.
            { Get-SNIncidentTask -IncidentTaskID 'TASKXXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { Get-SNIncidentTask -IncidentTaskID 'XTASKXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { Get-SNIncidentTask -IncidentTaskID 'ABCXXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }

        It 'Should accept strings that are 32 characters long and do not begin with TASK' {
            $stringValid = "A" * 32
            $stringInvalid1 = "A" * 31
            $stringInValid2 = "A" * 33
            { Get-SNIncidentTask -IncidentTaskID $stringValid -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { Get-SNIncidentTask -IncidentTaskID $stringInValid1 -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { Get-SNIncidentTask -IncidentTaskID $stringInValid2 -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }
    }
}