function Get-SNRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (($_ -match "^REQ.+$") -or ($_.length -eq 32)) {
                    return $true
                } else {
                    throw "RequestID can be either the Request number (REQ*******) or " +
                    "Request sys_id. If Request number is elected. It must contain REQ prefix. If not, it " +
                    "will be accepted as a sys_id. If the Request sys_id is elected. It must be at least 32 characters in length."
                }
            })]
        [string]$RequestID,

        # Switch between ServiceNow TEST and PROD instance.
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey
    )
    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/request/{1}' -f $Instance, $RequestID
        Method = 'GET'
    }
    Invoke-SNMethod @params
}