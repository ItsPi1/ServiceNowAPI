#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "Get-SNIncident" {
    Context "Parameters" {
        BeforeAll {
            $commandInfo = Get-Command Get-SNIncident
        }
        It 'Has a mandatory IncidentID parameter' {
            $incidentID = $commandInfo.Parameters['IncidentID']
            $incidentID | Should -Not -BeNullOrEmpty
            $incidentID.ParameterType | Should -Be ([string])
            $incidentID.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $incidentID.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
            $incidentID.Attributes.Where{ $_ -is [ValidateScript] }.ScriptBlock | Should -Not -BeNullOrEmpty # Do you have a better way of testing ValidateScript()?
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

    Context "Test Validate Script for IncidentID parameter" {
        BeforeAll {
            InModuleScope ServiceNowAPI {
                Mock Invoke-SNMethod { return $null }
            }
        }

        It 'Should accept strings that start with INC' {
            # Input to '-Throw' and '-Not -Throw' must be enclosed in curly braces.
            { Get-SNIncident -IncidentID 'INCXXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { Get-SNIncident -IncidentID 'XINCXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { Get-SNIncident -IncidentID 'ABCXXXXXX' -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }

        It 'Should accept strings that are 32 characters long and do not begin with INC' {
            $stringValid = "A" * 32
            $stringInvalid1 = "A" * 31
            $stringInValid2 = "A" * 33
            { Get-SNIncident -IncidentID $stringValid -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { Get-SNIncident -IncidentID $stringInValid1 -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { Get-SNIncident -IncidentID $stringInValid2 -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }
    }
}