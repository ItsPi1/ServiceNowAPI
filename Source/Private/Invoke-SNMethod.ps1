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