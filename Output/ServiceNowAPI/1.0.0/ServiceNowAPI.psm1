#Region '.\Private\Assert-RequiredKey.ps1' 0
function Assert-RequiredKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$RequiredKeys,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ProvidedKeys
    )
    $missingFields = foreach ($key in $RequiredKeys) {
        if ($ProvidedKeys.ContainsKey($key)) {
            $true
        } else {
            $false
        }
    }
    $requiredPresent = ! ($missingFields -contains $false)
    $requiredPresent
}
#EndRegion '.\Private\Assert-RequiredKey.ps1' 19
#Region '.\Private\Invoke-SNMethod.ps1' 0
function Invoke-SNMethod {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('GET', 'PATCH', 'POST')]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$URI,

        [object]$Body,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Header
    )
    $params = @{
        URI     = $URI
        Headers = $Header
        Method  = $Method
        EA      = 'Stop'
    }

    # If this parameter is omitted and the request method is POST, Invoke-RestMethod sets the content type to application/x-www-form-urlencoded
    # Which will produce an InvalidRequestContent error in our case.
    if ($PSBoundParameters['Method'] -eq 'POST') {
        $params.Add('ContentType', 'application/json')
    }

    # Add body
    if ($PSBoundParameters['Body']) {
        # The api is case sensitive, fields must be all lower case.
        $Body = Set-KeysToLowerCase -InputTable $Body
        # When the input is a GET request, and the body is an IDictionary (typically, a hash table), the body is added to the Uniform Resource Identifier (URI) as query parameters.
        # For other request types (such as POST), the body is set as the value of the request body in the standard name=value format.
        if ($PSBoundParameters['Method'] -ne 'GET') {
            $params.Add('Body', ($Body | ConvertTo-Json))
        } else {
            $params.Add('Body', $Body)
        }
    }

    try {
        if ($PSCmdlet.ShouldProcess($Method, $URI)) {
            $results = Invoke-RestMethod @params
        }
    } catch [System.Net.WebException] {
        $err = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($null -ne $err.exceptions) {
            return $err.exceptions.exception.outputs
        } elseif ($null -ne $err.error) {
            return $err.error
        } else {
            return $err
        }
    }
    # Our data is nested under a property with the same name as the table
    # This will allow us to extract it regardless of the table queried.
    $property = $results | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    $results | Select-Object -ExpandProperty $property
}
#EndRegion '.\Private\Invoke-SNMethod.ps1' 60
#Region '.\Private\Select-ActiveParameter.ps1' 0
function Select-ActiveParameter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$BoundParameters,

        [switch]$HashTable
    )
    $data = switch ($BoundParameters.Keys) {
        'Name' { @( 'name' , $BoundParameters['Name'] ) }
        'AssetTag' { @( 'asset_tag' , $BoundParameters['AssetTag'] ) }
        'SysID' { @( 'sys_id' , $BoundParameters['SysID'] ) }
    }
    # Convert the array to a hashtable
    if ($HashTable) {
        @{ $data[0] = $data[1] }
    } else {
        $data
    }
}
#EndRegion '.\Private\Select-ActiveParameter.ps1' 20
#Region '.\Private\Set-KeysToLowerCase.ps1' 0
function Set-KeysToLowerCase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$InputTable
    )
    $outputTable = @{}
    $InputTable.GetEnumerator() | ForEach-Object {
        $lowerCaseKey = ($_.Key | Out-String).Trim().ToLower()
        $outputTable.Add($lowerCaseKey, $_.Value)
    }
    $outputTable
}
#EndRegion '.\Private\Set-KeysToLowerCase.ps1' 13
#Region '.\Public\Get-SNComputerConfigurationItem.ps1' 0
function Get-SNComputerConfigurationItem {
    [CmdletBinding()]
    param (
        # Configuration Item Name or Asset Tag as found in the cmdb_ci table.
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'AssetTag')]
        [ValidateNotNullOrEmpty()]
        [string]$AssetTag,

        # Configuration Item sys_id as found in the cmdb_ci table. Must be 32 characters in length.
        [Parameter(Mandatory, ParameterSetName = 'SysID')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(32, 32)]
        [string]$SysID,

        # Switch between ServiceNow TEST and PROD instance.
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'SysID')]
        [Parameter(ParameterSetName = 'AssetTag')]
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        # APIM Subscription Key
        [Parameter(Mandatory)]
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'SysID')]
        [Parameter(ParameterSetName = 'AssetTag')]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey
    )

    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/cmdb_ci_computer' -f $Instance
        Method = 'GET'
    }
    $params.Add('Body', (Select-ActiveParameter -BoundParameters $PSBoundParameters -HashTable))
    Invoke-SNMethod @params
}
#EndRegion '.\Public\Get-SNComputerConfigurationItem.ps1' 42
#Region '.\Public\Get-SNConfigurationItem.ps1' 0
function Get-SNConfigurationItem {
    [CmdletBinding()]
    param (
        # Configuration Item Name or Asset Tag as found in the cmdb_ci table.
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'AssetTag')]
        [ValidateNotNullOrEmpty()]
        [string]$AssetTag,

        # Configuration Item sys_id as found in the cmdb_ci table. Must be 32 characters in length.
        [Parameter(Mandatory, ParameterSetName = 'SysID')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(32, 32)]
        [string]$SysID,

        # Switch between ServiceNow TEST and PROD instance.
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'SysID')]
        [Parameter(ParameterSetName = 'AssetTag')]
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        # APIM Subscription Key
        [Parameter(Mandatory)]
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'SysID')]
        [Parameter(ParameterSetName = 'AssetTag')]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey
    )
    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/cmdb_ci' -f $Instance
        Method = 'GET'
    }
    $params.Add('Body', (Select-ActiveParameter -BoundParameters $PSBoundParameters -HashTable))
    Invoke-SNMethod @params
}
#EndRegion '.\Public\Get-SNConfigurationItem.ps1' 41
#Region '.\Public\Get-SNIncident.ps1' 0
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
#EndRegion '.\Public\Get-SNIncident.ps1' 31
#Region '.\Public\Get-SNIncidentTask.ps1' 0
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
#EndRegion '.\Public\Get-SNIncidentTask.ps1' 31
#Region '.\Public\Get-SNRequest.ps1' 0
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
#EndRegion '.\Public\Get-SNRequest.ps1' 31
#Region '.\Public\Get-SNRequestItem.ps1' 0
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
#EndRegion '.\Public\Get-SNRequestItem.ps1' 31
#Region '.\Public\Get-SNRequestTask.ps1' 0
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
#EndRegion '.\Public\Get-SNRequestTask.ps1' 31
#Region '.\Public\New-SNIncident.ps1' 0
function New-SNIncident {
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

    $requiredFields = @('assignment_group', 'caller_id', 'category', 'contact_type', 'description', 'short_description')
    $requiredPresent = Assert-RequiredKey -RequiredKeys $requiredFields -Provided $Fields
    if (! $requiredPresent) {
        throw "Ticket fields must contain {0}, {1}, {2}, {3}, {4}, and {5}." -f $requiredFields
    }

    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = "https://{servicenow}/incident/new" -f $Instance
        Method = 'POST'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $message = 'Performing the operation "New Incident" on target Service Now.'
    $warning = "Are you sure you want to create a new Incident in Service Now."
    $caption = "Create New Incident"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params -WhatIf:$WhatIfPreference
    }
}
#EndRegion '.\Public\New-SNIncident.ps1' 51
#Region '.\Public\New-SNIncidentTask.ps1' 0
function New-SNIncidentTask {
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

    $requiredFields = @('assignment_group', 'description', 'short_description')
    $requiredPresent = Assert-RequiredKey -RequiredKeys $requiredFields -Provided $Fields
    if (! $requiredPresent) {
        throw "Ticket fields must contain {0}, {1}, and {2}." -f $requiredFields
    }

    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = "https://{servicenow}/incident_task/new" -f $Instance
        Method = 'POST'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $message = 'Performing the operation "New Incident Task" on target Service Now.'
    $warning = "Are you sure you want to create a new Incident Task in Service Now."
    $caption = "Create New Incident Task"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params -WhatIf:$WhatIfPreference
    }
}
#EndRegion '.\Public\New-SNIncidentTask.ps1' 52
#Region '.\Public\New-SNRequest.ps1' 0
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
#EndRegion '.\Public\New-SNRequest.ps1' 52
#Region '.\Public\New-SNRequestItem.ps1' 0
function New-SNRequestItem {
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

    $requiredFields = @('request', 'cat_item', 'cmdb_ci', 'requested_for', 'description', 'short_description')
    $requiredPresent = Assert-RequiredKey -RequiredKeys $requiredFields -Provided $Fields
    if (! $requiredPresent) {
        throw "Ticket fields must contain {0}, {1}, {2}, {3}, {4}, {5}, {6}, and {7}." -f $requiredFields
    }

    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = "https://{servicenow}/request_item/new" -f $Instance
        Method = 'POST'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $message = 'Performing the operation "New Request Item" on target Service Now.'
    $warning = "Are you sure you want to create a new Request Task Item in Service Now."
    $caption = "Create New Request Task Item"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params -WhatIf:$WhatIfPreference
    }
}
#EndRegion '.\Public\New-SNRequestItem.ps1' 52
#Region '.\Public\New-SNRequestTask.ps1' 0
function New-SNRequestTask {
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

    $requiredFields = @('parent', 'request', 'request_item', 'cmdb_ci', 'assignment_group', 'assigned_to', 'description', 'short_description')
    $requiredPresent = Assert-RequiredKey -RequiredKeys $requiredFields -Provided $Fields
    if (! $requiredPresent) {
        throw "Ticket fields must contain {0}, {1}, {2}, {3}, {4}, {5}, {6}, and {7}." -f $requiredFields
    }

    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = "https://{servicenow}/request_task/new" -f $Instance
        Method = 'POST'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $message = 'Performing the operation "New Request Task" on target Service Now.'
    $warning = "Are you sure you want to create a new Request Task in Service Now."
    $caption = "Create New Request Task"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params -WhatIf:$WhatIfPreference
    }
}
#EndRegion '.\Public\New-SNRequestTask.ps1' 52
#Region '.\Public\Update-SNComputerConfigurationItem.ps1' 0
function Update-SNComputerConfigurationItem {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Configuration Item Name or Asset Tag as found in the cmdb_ci table.
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'AssetTag')]
        [ValidateNotNullOrEmpty()]
        [string]$AssetTag,

        # Configuration Item sys_id as found in the cmdb_ci table. Must be 32 characters in length.
        [Parameter(Mandatory, ParameterSetName = 'SysID')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(32, 32)]
        [string]$SysID,

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
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'SysID')]
        [Parameter(ParameterSetName = 'AssetTag')]
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        # APIM Subscription Key
        [Parameter(Mandatory)]
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'SysID')]
        [Parameter(ParameterSetName = 'AssetTag')]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey,

        [switch]$Force
    )
    $queryParams = Select-ActiveParameter -BoundParameters $PSBoundParameters

    <#
    InvalidOperation: Error formatting a string: Index (zero based) must be greater 
    than or equal to zero and less than the size of the argument list..
    $a = 1,2
    $b = 3
    "{0}{1}{2}" -f $a, $b
    So we have to split it up to make an array of the correct size. I didnt want to use string interpolation
    #>
    $queryParams_1 = $queryParams[0]
    $queryParams_2 = $queryParams[1]
    $format = $Instance, $queryParams_1, $queryParams_2

    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/cmdb_ci_computer/update?{1}={2}' -f $format
        Method = 'PATCH'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $target = $queryParams[1]
    $message = "Performing the operation `"Update Computer Configuration Item`" on target $target in Service Now."
    $warning = "Are you sure you want to Update the Computer Configuration Item $target in Service Now."
    $caption = "Update Computer Configuration Item"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params
    }
}
#EndRegion '.\Public\Update-SNComputerConfigurationItem.ps1' 82
#Region '.\Public\Update-SNConfigurationItem.ps1' 0
function Update-SNConfigurationItem {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Configuration Item Name or Asset Tag as found in the cmdb_ci table.
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'AssetTag')]
        [ValidateNotNullOrEmpty()]
        [string]$AssetTag,

        # Configuration Item sys_id as found in the cmdb_ci table. Must be 32 characters in length.
        [Parameter(Mandatory, ParameterSetName = 'SysID')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(32, 32)]
        [string]$SysID,

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
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'SysID')]
        [Parameter(ParameterSetName = 'AssetTag')]
        [ValidateSet("PROD", "TEST")]
        [string]$Instance = "PROD",

        # APIM Subscription Key
        [Parameter(Mandatory)]
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'SysID')]
        [Parameter(ParameterSetName = 'AssetTag')]
        [ValidateNotNullOrEmpty()]
        [string]$APIMSubscriptionKey,

        [switch]$Force
    )
    $queryParams = Select-ActiveParameter -BoundParameters $PSBoundParameters

    <#
    InvalidOperation: Error formatting a string: Index (zero based) must be greater 
    than or equal to zero and less than the size of the argument list..
    $a = 1,2
    $b = 3
    "{0}{1}{2}" -f $a, $b
    So we have to split it up to make an array of the correct size. I didnt want to use string interpolation
    #>
    $queryParams_1 = $queryParams[0]
    $queryParams_2 = $queryParams[1]
    $format = $Instance, $queryParams_1, $queryParams_2

    $params = @{
        Header = @{ 'Ocp-Apim-Subscription-Key' = $APIMSubscriptionKey }
        URI    = 'https://{servicenow}/cmdb_ci/update?{1}={2}' -f $format
        Method = 'PATCH'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $target = $queryParams[1]
    $message = "Performing the operation `"Update Configuration Item`" on target $target in Service Now."
    $warning = "Are you sure you want to Update the Configuration Item $target in Service Now."
    $caption = "Update Configuration Item"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params
    }
}
#EndRegion '.\Public\Update-SNConfigurationItem.ps1' 82
#Region '.\Public\Update-SNIncident.ps1' 0
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
#EndRegion '.\Public\Update-SNIncident.ps1' 59
#Region '.\Public\Update-SNIncidentTask.ps1' 0
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
#EndRegion '.\Public\Update-SNIncidentTask.ps1' 59
#Region '.\Public\Update-SNRequest.ps1' 0
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
#EndRegion '.\Public\Update-SNRequest.ps1' 59
#Region '.\Public\Update-SNRequestItem.ps1' 0
function Update-SNRequestItem {
    [CmdletBinding(SupportsShouldProcess)]
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
        URI    = "https://{servicenow}/request_item/update/{1}" -f $Instance, $RequestItemID
        Method = 'PATCH'
        Body   = $Fields
    }

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $target = $RequestItemID
    $message = "Performing the operation `"Update Request Item`" on target $target in Service Now."
    $warning = "Are you sure you want to Update the Request Item $target in Service Now."
    $caption = "Update Request Item"
    if ($PSCmdlet.ShouldProcess($message, $warning, $caption)) {
        Invoke-SNMethod @params
    }
}
#EndRegion '.\Public\Update-SNRequestItem.ps1' 59
#Region '.\Public\Update-SNRequestTask.ps1' 0
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
#EndRegion '.\Public\Update-SNRequestTask.ps1' 59
