function Get-SNIncident {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (($_ -match "^INC.+$") -or ($_.length -eq 32)) {
                    return $true
                } else {
                    throw "IncidentID can be either the Incident number (INC*******) or " +
                    "Incident sys_id. If Incident number is elected. It must contain INC prefix. If not, it " +
                    "will be accepted as a sys_id. If the Incident sys_id is elected. It must be at least 32 characters in length."
                }
            })]
        [string]$IncidentID,

        # Switch between ServiceNow TEST and PROD instance.
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey
    )
    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/incident/{1}' -f $Instance, $IncidentID
        Method = 'GET'
    }
    Invoke-SNMethod @params
}