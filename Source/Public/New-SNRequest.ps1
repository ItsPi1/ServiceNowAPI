function New-SNRequest {
    [CmdletBinding(SupportsShouldProcess)]
    param (
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

    $requiredFields = @('description', 'short_description')
    $requiredPresent = Assert-RequiredKey -RequiredKeys $requiredFields -Provided $Fields
    if (! $requiredPresent) {
        throw "Ticket fields must contain {0}, {1}, and {2}." -f $requiredFields
    }

    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = "https://{servicenow}/request/new" -f $Instance
        Method = 'POST'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $message = 'Performing the operation "New Request" on target Service Now.'
    $warning = "Are you sure you want to create a new Request in Service Now."
    $caption = "Create New Request"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params -WhatIf:$WhatIfPreference
    }
}