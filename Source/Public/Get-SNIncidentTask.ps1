function Get-SNIncidentTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (($_ -match "^TASK.+$") -or ($_.length -eq 32)) {
                    return $true
                } else {
                    throw "IncidentTaskID can be either the Incident number (TASK*******) or " +
                    "Incident sys_id. If Incident number is elected. It must contain TASK prefix. If not, it " +
                    "will be accepted as a sys_id. If the Incident sys_id is elected. It must be at least 32 characters in length."
                }
            })]
        [string]$IncidentTaskID,

        # Switch between ServiceNow TEST and PROD instance.
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey
    )
    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/incident_task/{1}' -f $Instance, $IncidentTaskID
        Method = 'GET'
    }
    Invoke-SNMethod @params
}