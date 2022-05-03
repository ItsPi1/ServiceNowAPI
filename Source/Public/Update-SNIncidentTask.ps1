function Update-SNIncidentTask {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (($_ -match "^TASK.+$") -or ($_.length -eq 32)) {
                    return $true
                } else {
                    throw "IncidentTaskID can be either the Incident Task number (TASK*******) or " +
                    "Incident Task sys_id. If Incident Task number is elected. It must contain TASK prefix. If not, it " +
                    "will be accepted as a sys_id. If the Incident Task sys_id is elected. It must be at least 32 characters in length."
                }
            })]
        [string]$IncidentTaskID,

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
        URI    = "https://{servicenow}/incident_task/update/{1}" -f $Instance, $IncidentTaskID
        Method = 'PATCH'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $target = $IncidentTaskID
    $message = "Performing the operation `"Update Incident Task`" on target $target in Service Now."
    $warning = "Are you sure you want to Update the Incident Task $target in Service Now."
    $caption = "Update Incident Task"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params
    }
}