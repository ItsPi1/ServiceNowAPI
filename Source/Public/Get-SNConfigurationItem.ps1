function Get-SNConfigurationItem {
    [CmdletBinding()]
    param (
        # Configuration Item Name or Asset Tag as found in the cmdb_ci table.
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'AssetTag')]
        [ValidateNotNullOrEmpty()]
        [string]$AssetTag,

        # Configuration Item sys_id as found in the cmdb_ci table. Must be 32 characters in length.
        [Parameter(Mandatory, ParameterSetName = 'SysID')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(32, 32)]
        [string]$SysID,

        # Switch between ServiceNow TEST and PROD instance.
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'SysID')]
        [Parameter(ParameterSetName = 'AssetTag')]
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        # APIM Subscription Key
        [Parameter(Mandatory)]
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'SysID')]
        [Parameter(ParameterSetName = 'AssetTag')]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey
    )
    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/cmdb_ci' -f $Instance
        Method = 'GET'
    }
    $params.Add('Body', (Select-ActiveParameter -BoundParameters $PSBoundParameters -HashTable))
    Invoke-SNMethod @params
}