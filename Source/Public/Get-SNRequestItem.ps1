function Get-SNRequestItem {
    [CmdletBinding()]
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

        # Switch between ServiceNow TEST and PROD instance.
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey
    )
    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/request_item/{1}' -f $Instance, $RequestItemID
        Method = 'GET'
    }
    Invoke-SNMethod @params
}