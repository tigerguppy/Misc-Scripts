$IpA = 10
$IpB = 1
$IpC = 0
$IpD = 1..25

$Ports = 80, 443, 3389..3392

$Timeout = 100 # milliseconds

# Do not edit below this line.

function TestPort (
    $Hostname = 'google.com', 
    $Port = 80, 
    $Timeout = 100) {
        
    $requestCallback = $state = $null
    $client = New-Object System.Net.Sockets.TcpClient
    $beginConnect = $client.BeginConnect($hostname, $port, $requestCallback, $state)
    Start-Sleep -milli $timeOut
    if ($client.Connected) { $open = $true } else { $open = $false }
    $client.Close()
    [pscustomobject]@{
        Hostname = $hostname
        Port     = $port
        Open     = $open 
    }
}

$TotalChecks = $($IpA | Measure-Object).Count * $($IpB | Measure-Object).Count * $($IpC | Measure-Object).Count * $($IpD | Measure-Object).Count * $($Ports | Measure-Object).Count

[System.Collections.ArrayList]$ResultsFound = @{}
[System.Collections.ArrayList]$ResultsNotFound = @{}

$Found = 0
$NotFound = 0
$CurrentTest = 0

foreach ($A in $IpA) {
    foreach ($B in $IpB) {
        foreach ($C in $IpC) {
            foreach ($D in $IpD) {
                $IpAddress = "$A.$B.$C.$D"
                
                foreach ($Port in $Ports) {
                    $PercentComplete = $($CurrentTest / $TotalChecks) * 100
                    Write-Progress -Activity "Testing $Port on $IpAddress" -Status "Test: $CurrentTest / $TotalChecks. Found: $Found" -PercentComplete $PercentComplete -Completed
                    
                    $Test = TestPort -Hostname $IpAddress -Port $Port -Timeout $Timeout

                    if ($Test.open) {
                        $Found ++
                        $ResultsFound.add($Test) | Out-Null
                    } else {
                        $NotFound ++
                        $ResultsNotFound.add($Test) | Out-Null
                    }

                    $CurrentTest ++
                }
            }
        }
    }
}

Write-Output "Found: $Found / Not Found: $NotFound / Total: $TotalChecks"

Write-Output 'Found Open Ports:'
$ResultsFound | Format-Table -AutoSize
