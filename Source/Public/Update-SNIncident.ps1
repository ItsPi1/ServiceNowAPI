function Update-SNIncident {
    [CmdletBinding(SupportsShouldProcess)]
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
        URI    = "https://{servicenow}/incident/update/{1}" -f $Instance, $IncidentID
        Method = 'PATCH'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $target = $IncidentID
    $message = "Performing the operation `"Update Incident`" on target $target in Service Now."
    $warning = "Are you sure you want to Update the Incident $target in Service Now."
    $caption = "Update Incident"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params
    }
}