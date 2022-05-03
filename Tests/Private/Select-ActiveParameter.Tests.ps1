#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "Select-ActiveParameter" {
    Context "Necessary Parameters" {
        BeforeAll {
            $CommandInfo = InModuleScope ServiceNowAPI { Get-Command Select-ActiveParameter }
        }
        It 'has a mandatory BoundParameters parameter' {
            $BoundParameters = $CommandInfo.Parameters['BoundParameters']
            $BoundParameters | Should -Not -BeNullOrEmpty
            $BoundParameters.ParameterType | Should -Be ([System.Collections.IDictionary])
            $BoundParameters.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
        }

        It 'has an optional Hashtable switch parameter' {
            $Hashtable = $CommandInfo.Parameters['Hashtable']
            $Hashtable | Should -Not -BeNullOrEmpty
            $Hashtable.ParameterType | Should -Be ([switch])
            $Hashtable.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $false
        }
    }

    Context "Returns object of correct type" {
        InModuleScope ServiceNowAPI {
            BeforeAll {
                function Test-AP ($Name) {
                    [PSCustomObject]@{
                        Array     = Select-ActiveParameter $PSBoundParameters
                        Hashtable = Select-ActiveParameter $PSBoundParameters -HashTable
                    }
                }
            }
            It 'returns an array of count 2 if Hashtable switch is not used' {
                $result = Test-AP -Name 'Name' | Select-Object -ExpandProperty Array
                $result | Should -HaveCount 2
                # https://github.com/pester/Pester/issues/386
                # $result | Should -BeOfType [array] does not work see above for explanation
                Write-Output -NoEnumerate $result | Should -BeOfType [array]
            }

            It 'returns a hashtable of count 1 if the Hashtable switch is used' {
                $result = Test-AP -Name 'Name' | Select-Object -ExpandProperty Hashtable
                $result | Should -HaveCount 1
                $result | Should -BeOfType [System.Collections.IDictionary]
            }
        }
    }
}