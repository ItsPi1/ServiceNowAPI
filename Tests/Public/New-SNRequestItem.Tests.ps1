#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "New-SNRequestItem" {
    BeforeAll {
        $commandInfo = Get-Command New-SNRequestItem
    }
    Context "Parameters" {
        It 'Has a mandatory Fields parameter' {
            $fields = $commandInfo.Parameters['Fields']
            $fields | Should -Not -BeNullOrEmpty
            $fields.ParameterType | Should -Be ([System.Collections.IDictionary])
            $fields.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $fields.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
            $fields.Attributes.Where{ $_ -is [ValidateScript] }.ScriptBlock | Should -Not -BeNullOrEmpty # Do you have a better way of testing ValidateScript()?
        }

        It 'Has a mandatory APIMSubscriptionKey parameter' {
            $APIMSubscriptionKey = $commandInfo.Parameters['APIMSubscriptionKey']
            $APIMSubscriptionKey | Should -Not -BeNullOrEmpty
            $APIMSubscriptionKey.ParameterType | Should -Be ([string])
            $APIMSubscriptionKey.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $APIMSubscriptionKey.Attributes.Where{ $_ -is [Parameter] }.ParameterSetName | Should -Contain "__AllParameterSets"
            $APIMSubscriptionKey.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
        }

        It 'Has an optional Force parameter' {
            $force = $commandInfo.Parameters['Force']
            $force | Should -Not -BeNullOrEmpty
            $force.ParameterType | Should -Be ([switch])
            $force.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $false
        }
    }

    Context "CmdletBinding" {
        BeforeAll {
            $cmdletBinding = $commandInfo.ScriptBlock.Attributes.Where{ $_ -is [CmdletBinding] } # https://github.com/PowerShell/PowerShell/issues/10643
        }

        It 'Supports Should Process' {
            $cmdletBinding.SupportsShouldProcess | Should -Be $true
        }

        It 'ConfirmImpact is Medium' {
            $cmdletBinding.ConfirmImpact | Should -Be $true
        }
    }

    Context "Test Validate Script for Fields parameter" {
        BeforeAll {
            Mock -ModuleName ServiceNowAPI Assert-RequiredKey { return $true }
            Mock -ModuleName ServiceNowAPI Invoke-SNMethod { return $true }
        }

        It 'Should not accepts hashtables with Keys that begin with sys_' {
            # Input to '-Throw' and '-Not -Throw' must be enclosed in curly braces.
            { New-SNRequestItem -Fields @{ sys_AnInvalidKey = 'Value1' } -APIMSubscriptionKey 'XXXXX' } | Should -Throw
            { New-SNRequestItem -Fields @{ sys_AnInvalidKey2 = 'Value2' } -APIMSubscriptionKey 'XXXXX' } | Should -Throw
        }

        It 'Should accept hashtables with Keys that do not begin with sys_' {
            { New-SNRequestItem -Fields @{ TestKey = 'Pineapple' } -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
            { New-SNRequestItem -Fields @{ AValidKey = 'Value' } -APIMSubscriptionKey 'XXXXX' } | Should -Not -Throw
        }
    }
}