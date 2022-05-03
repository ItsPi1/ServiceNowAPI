function Update-SNRequestItem {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (($_ -match "^RITM.+$") -or ($_.length -eq 32)) {
                    return $true
                } else {
                    throw "RequestItemID can be either the Request Item number (RITM*******) or " +
                    "Request Item sys_id. If Request Item number is elected. It must contain RITM prefix. If not, it " +
                    "will be accepted as a sys_id. If the Request Item sys_id is elected. It must be at least 32 characters in length."
                }
            })]
        [string]$RequestItemID,

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
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey,

        [switch]$Force
    )
    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = "https://{servicenow}/request_item/update/{1}" -f $Instance, $RequestItemID
        Method = 'PATCH'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $target = $RequestItemID
    $message = "Performing the operation `"Update Request Item`" on target $target in Service Now."
    $warning = "Are you sure you want to Update the Request Item $target in Service Now."
    $caption = "Update Request Item"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params
    }
}