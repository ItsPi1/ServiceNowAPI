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