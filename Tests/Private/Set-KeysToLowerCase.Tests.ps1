#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "Set-KeysToLowerCase" {
    BeforeAll {
        $CommandInfo = InModuleScope ServiceNowAPI { Get-Command Set-KeysToLowerCase }
    }
    It 'has a mandatory InputTable parameter' {
        $InputTable = $CommandInfo.Parameters['InputTable']
        $InputTable | Should -Not -BeNullOrEmpty
        $InputTable.ParameterType | Should -Be ([System.Collections.IDictionary])
        $InputTable.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
    }

    InModuleScope ServiceNowAPI {
        BeforeEach {
            $aTable = @{
                UpperCaseKey   = 'Value'
                lowercasekey   = 'Another Value'
                AvArIngcAsEkEy = 'UhNuther Value'
            }
        }
        It "Will generate new hashtable with all lowercase keys" {
            $result = Set-KeysToLowerCase $aTable
            $result | Should -match "[a-z]"
            # https://github.com/pester/Pester/issues/1234
            #$result | Should -HaveCount 2 see above
            $result.GetEnumerator() | Should -HaveCount $aTable.Count
        }
    }
}