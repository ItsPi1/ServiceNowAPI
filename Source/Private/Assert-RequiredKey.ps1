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