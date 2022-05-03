function Update-SNRequest {
    [CmdletBinding(SupportsShouldProcess)]
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
        URI    = "https://{servicenow}/request/update/{1}" -f $Instance, $RequestID
        Method = 'PATCH'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $target = $RequestID
    $message = "Performing the operation `"Update Request`" on target $target in Service Now."
    $warning = "Are you sure you want to Update the Request $target in Service Now."
    $caption = "Update Request"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params
    }
}