function Get-SNRequestTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (($_ -match "^SCTASK.+$") -or ($_.length -eq 32)) {
                    return $true
                } else {
                    throw "RequestTaskID can be either the Request Task number (SCTASK*******) or " +
                    "Request Task sys_id. If Request Task number is elected. It must contain SCTASK prefix. If not, it " +
                    "will be accepted as a sys_id. If the Request Task sys_id is elected. It must be at least 32 characters in length."
                }
            })]
        [string]$RequestTaskID,

        # Switch between ServiceNow TEST and PROD instance.
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey
    )
    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/request_task/{1}' -f $Instance, $RequestTaskID
        Method = 'GET'
    }
    Invoke-SNMethod @params
}