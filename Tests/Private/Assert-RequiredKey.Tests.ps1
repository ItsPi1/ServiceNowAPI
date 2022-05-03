#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "Assert-RequiredKey" {
    Context "Necessary Parameters" {
        BeforeAll {
            $CommandInfo = InModuleScope ServiceNowAPI { Get-Command Assert-RequiredKey }
        }
        It 'has a mandatory RequiredKeys parameter' {
            $RequiredKeys = $CommandInfo.Parameters['RequiredKeys']
            $RequiredKeys | Should -Not -BeNullOrEmpty
            $RequiredKeys.ParameterType | Should -Be ([string[]])
            $RequiredKeys.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
        }

        It 'has a mandatory ProvidedKeys parameter' {
            $ProvidedKeys = $CommandInfo.Parameters['ProvidedKeys']
            $ProvidedKeys | Should -Not -BeNullOrEmpty
            $ProvidedKeys.ParameterType | Should -Be ([System.Collections.IDictionary])
            $ProvidedKeys.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
        }
    }

    Context "Returns proper bools" {
        InModuleScope ServiceNowAPI {
            It 'returns a bool' {
                $result = Assert-RequiredKey -RequiredKeys @('Key1', 'Key2') -ProvidedKeys @{ Key1 = 'Value1'; Key2 = 'Value2'; Key3 = 'Value3' }
                $result | Should -BeOfType [bool]
            }

            It 'returns $true when required keys are present' {
                $result = Assert-RequiredKey -RequiredKeys @('Key1', 'Key2') -ProvidedKeys @{ Key1 = 'Value1'; Key2 = 'Value2'; Key3 = 'Value3' }
                $result | Should -Be $true
            }

            It 'returns $false when required keys are not present' {
                $result = Assert-RequiredKey -RequiredKeys @('Key1', 'Key2', 'Key3') -ProvidedKeys @{ Key1 = 'Value1'; Key2 = 'Value2' }
                $result | Should -Be $false
            }
        }
    }
}