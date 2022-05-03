function Update-SNComputerConfigurationItem {
    [CmdletBinding(SupportsShouldProcess)]
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

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                foreach ($key in $_.Keys) {
                    if ($key -match "^(?!sys_).+$") {
                        $true
                    } else {
                        throw "Fields that have a prefix of 'sys_' are typically system parameters that are automatically generated and cannot be updated."
                    }
                
                }
            })]
        [System.Collections.IDictionary]$Fields,

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
        [string]$APIMSubscriptionKey,

        [switch]$Force
    )
    $queryParams = Select-ActiveParameter -BoundParameters $PSBoundParameters

    <#
    InvalidOperation: Error formatting a string: Index (zero based) must be greater 
    than or equal to zero and less than the size of the argument list..
    $a = 1,2
    $b = 3
    "{0}{1}{2}" -f $a, $b
    So we have to split it up to make an array of the correct size. I didnt want to use string interpolation
    #>
    $queryParams_1 = $queryParams[0]
    $queryParams_2 = $queryParams[1]
    $format = $Instance, $queryParams_1, $queryParams_2

    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/cmdb_ci_computer/update?{1}={2}' -f $format
        Method = 'PATCH'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $target = $queryParams[1]
    $message = "Performing the operation `"Update Computer Configuration Item`" on target $target in Service Now."
    $warning = "Are you sure you want to Update the Computer Configuration Item $target in Service Now."
    $caption = "Update Computer Configuration Item"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params
    }
}