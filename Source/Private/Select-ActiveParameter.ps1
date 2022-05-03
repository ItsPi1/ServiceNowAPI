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