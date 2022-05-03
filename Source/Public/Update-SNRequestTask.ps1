function Update-SNRequestTask {
    [CmdletBinding(SupportsShouldProcess)]
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
        URI    = "https://{servicenow}/request_task/update/{1}" -f $Instance, $RequestTaskID
        Method = 'PATCH'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $target = $RequestTaskID
    $message = "Performing the operation `"Update Request Task`" on target $target in Service Now."
    $warning = "Are you sure you want to Update the Request Task $target in Service Now."
    $caption = "Update Request Task"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params
    }
}