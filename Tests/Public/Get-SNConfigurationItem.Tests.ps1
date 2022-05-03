#requires -Modules @{ ModuleName = "ServiceNowAPI"; ModuleVersion =  "1.0.0" }
#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }
#requires -Version 5.1
Describe "Get-SNConfigurationItem" {
    Context "Parameters" {
        BeforeAll {
            $commandInfo = Get-Command Get-SNConfigurationItem
        }
        It 'Has a mandatory Name parameter' {
            $name = $commandInfo.Parameters['Name']
            $name | Should -Not -BeNullOrEmpty
            $name.ParameterType | Should -Be ([string])
            $name.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $name.Attributes.Where{ $_ -is [Parameter] }.ParameterSetName | Should -Be "Name"
            $name.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
        }

        It 'Has a mandatory AssetTag parameter' {
            $assetTag = $commandInfo.Parameters['AssetTag']
            $assetTag | Should -Not -BeNullOrEmpty
            $assetTag.ParameterType | Should -Be ([string])
            $assetTag.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $assetTag.Attributes.Where{ $_ -is [Parameter] }.ParameterSetName | Should -Be "AssetTag"
            $assetTag.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
        }

        It 'Has a mandatory SysID parameter' {
            $sysID = $commandInfo.Parameters['SysID']
            $sysID | Should -Not -BeNullOrEmpty
            $sysID.ParameterType | Should -Be ([string])
            $sysID.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be $true
            $sysID.Attributes.Where{ $_ -is [Parameter] }.ParameterSetName | Should -Be "SysID"
            $sysID.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
        }

        It 'Has a mandatory APIMSubscriptionKey parameter' {
            $APIMSubscriptionKey = $commandInfo.Parameters['APIMSubscriptionKey']
            $APIMSubscriptionKey | Should -Not -BeNullOrEmpty
            $APIMSubscriptionKey.ParameterType | Should -Be ([string])
            $APIMSubscriptionKey.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Be @($false, $false, $false, $true) # $true for __AllParameterSets
            $APIMSubscriptionKey.Attributes.Where{ $_ -is [Parameter] }.ParameterSetName | Should -Contain "__AllParameterSets"
            $APIMSubscriptionKey.Attributes.Where{ $_ -is [ValidateNotNullOrEmpty] } | Should -Not -BeNullOrEmpty
        }
    }
}