param
(
    [string]$PathToCSV
)

if(!(Test-Path $PathToCSV))
{
    Write-Host "$PathToCsv is does not exist....." -ForegroundColor Red
    Exit
}


$notFound = 0 
$cves = (Import-Csv -Path $PathToCSV).cve

foreach ($cve in $cves) {
    if ([String]::IsNullOrWhiteSpace($cve)) {
        continue
    }
    $cve
    $uri = "https://www.rapid7.com/db/?q=$cve&type=nexpose"
    $response = Invoke-WebRequest -Uri $uri
    $hit = $response.Content | Select-String "No results"
    if ($hit) {
        $notFound ++
        $cve >> "./cvesNotFound.txt"
        Write-Host "CVE $cve NOT found in db." -ForegroundColor Yellow
        continue
    }

    Write-Host "CVE $cve found in db." -ForegroundColor Green
    
}

Write-Host "Total number of CVE's not found $notFound" -ForegroundColor Green
