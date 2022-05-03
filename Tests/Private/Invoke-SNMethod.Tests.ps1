#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "Invoke-SNMethod" {
    Context "Necessary Parameters" {
        BeforeAll {
            $CommandInfo = InModuleScope ServiceNowAPI { Get-Command Invoke-SNMethod }
        }
        It 'has a mandatory Method parameter with a GET, PATCH, POST ValidateSet' {
            $Method = $CommandInfo.Parameters['Method']
            $Method | Should -Not -BeNullOrEmpty
            $Method.ParameterType | Should -Be ([string])
            $Method.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $method.Attributes.Where{ $_ -is [ValidateSet] }.ValidValues | Should -Be @('GET', 'PATCH', 'POST')
        }

        It 'has a mandatory URI parameter' {
            $URI = $CommandInfo.Parameters['URI']
            $URI | Should -Not -BeNullOrEmpty
            $URI.ParameterType | Should -Be ([string])
            $URI.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
        }

        It 'has a mandatory Header parameter' {
            $Header = $CommandInfo.Parameters['Header']
            $Header | Should -Not -BeNullOrEmpty
            $Header.ParameterType | Should -Be ([System.Collections.IDictionary])
            $Header.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
        }

        It 'has an optional Body parameter' {
            $Body = $CommandInfo.Parameters['Body']
            $Body | Should -Not -BeNullOrEmpty
            $Body.ParameterType | Should -Be ([object])
            $Body.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $false
        }
    }

    Context "Code Paths" {
        InModuleScope ServiceNowAPI {
            BeforeEach {
                function Compare-IDictionary {
                <#
                .SYNOPSIS
                Compare two Hashtables.
                #>
                    [CmdletBinding()]
                    param (
                        [Parameter(Mandatory = $true)]
                        [System.Collections.IDictionary]$Reference,

                        [Parameter(Mandatory = $true)]
                        [System.Collections.IDictionary]$Difference
                    )

                    foreach ($key in $Reference.Keys) {
                        if (!$Difference.ContainsKey($key)) {
                            return $false
                        } elseif ($Reference[$key] -ne $Difference[$key]) {
                            return $false
                        }
                    }

                    foreach ($key in $Difference.Keys) {
                        if (!$Reference.Contains($key)) {
                            return $false
                        } elseif ($Difference[$key] -ne $Reference[$key]) {
                            return $false
                        }
                    }
                    return $true
                }

                Mock Invoke-RestMethod { return $params }
                $inputBody = @{ inputbody = @{ Key = 'TestValue' } }
                $arguments = @{
                    URI    = 'InvalidValue'
                    Body   = $inputBody
                    Header = @{ Key = 'InvalidValue' }
                }
            }
            It "Should convert the body to JSON when invoking PATCH requests" {
                $arguments.Add('Method', 'PATCH')
                $expected = $inputBody | ConvertTo-Json

                $result = Invoke-SNMethod @arguments
                $result.Body | Should -Be $expected
            }

            It "Should convert the body to JSON when invoking POST requests" {
                $arguments.Add('Method', 'POST')
                $expected = $inputBody | ConvertTo-Json

                $result = Invoke-SNMethod @arguments
                $result.Body | Should -Be $expected
            }

            It "Should not convert the body to JSON when invoking GET requests" {
                $arguments.Add('Method', 'GET')

                $result = Invoke-SNMethod @arguments
                $result = Compare-IDictionary $result.Body $inputBody
                $result | Should -Be $true
            }

            It "Should add ContentType parameter with a value of application/json when invoking POST requests" {
                $arguments.Add('Method', 'POST')

                $result = Invoke-SNMethod @arguments
                $result.ContentType | Should -Not -BeNullOrEmpty
                $result.ContentType | Should -Be "application/json"
            }
        }
    }
}