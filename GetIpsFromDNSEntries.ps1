# James Ambrose

function Test-IsValidIPv6Address {
    param(
        [Parameter(Mandatory=$true,HelpMessage='Enter IPv6 address to verify')] [string] $IP)
    $IPv4Regex = '(((25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))'
    $G = '[a-f\d]{1,4}'
    # In a case sensitive regex, use:
    #$G = '[A-Fa-f\d]{1,4}'
    $Tail = @(":",
        "(:($G)?|$IPv4Regex)",
        ":($IPv4Regex|$G(:$G)?|)",
        "(:$IPv4Regex|:$G(:$IPv4Regex|(:$G){0,2})|:)",
        "((:$G){0,2}(:$IPv4Regex|(:$G){1,2})|:)",
        "((:$G){0,3}(:$IPv4Regex|(:$G){1,2})|:)",
        "((:$G){0,4}(:$IPv4Regex|(:$G){1,2})|:)")
    [string] $IPv6RegexString = $G
    $Tail | foreach { $IPv6RegexString = "${G}:($IPv6RegexString|$_)" }
    $IPv6RegexString = ":(:$G){0,5}((:$G){1,2}|:$IPv4Regex)|$IPv6RegexString"
    $IPv6RegexString = $IPv6RegexString -replace '\(' , '(?:' # make all groups non-capturing
    [regex] $IPv6Regex = $IPv6RegexString
    if ($IP -imatch "^$IPv6Regex$") {
        $true
    } else {
        $false
    }
}

$DropIPv6Addresses = "True"
$OUPUT_FILE_NAME = "IP Addresses.txt"
$CONFIG_FILE_NAME = "hostnames.conf"

[string[]]$arrayFromFile = Get-Content -Path $CONFIG_FILE_NAME
$IPAddresses = @()

foreach ($dnsHost in $arrayFromFile) {
    
    $tempIPValues = [System.Net.Dns]::GetHostEntry($dnsHost) | Select-Object  -Property "AddressList" -ExpandProperty addresslist | Select-Object "IPAddressToString" -ExpandProperty "IPAddressToString";

    [System.Net.Dns]::GetHostEntry($dnsHost)

    foreach ($ipaddress in $tempIPValues)
    {
        if (($(Test-IsValidIPv6Address -IP $ipaddress) -eq "True") -and ($DropIPv6Addresses -eq "True"))
        {
            echo "IPv6 is not supported within NSX-V, Dropping from output. This can be disabled by changing the 'DropIPv6Addresses' Variable to 'False'"
        }
        else
        {
            $IPAddresses += $ipaddress
        }
    }   
}

echo "============"
echo "OUTPUTTING IP ADDRESSES"
echo "============"
echo ($($IPAddresses) -join ",")
echo "============"
echo "OUTPUTTING TO $OUPUT_FILE_NAME"
echo "============"
echo ($($IPAddresses) -join ",") | Out-File ./$OUPUT_FILE_NAME