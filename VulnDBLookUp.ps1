<#
Does a cve lookup against vuln db @rapid7.com/db parsing the raw output of the html on 'No Result'

Outputs cve's not found in db to file "cvesNotFound.txt" in the pwd

Example usage:
./VulnDB.ps1 -PathToCSV ./boacve.csv

C:\temp\VulnDB.ps1 -PathToCSV "C:\temp\boacve.csv"

Assumptions:
CSV has a header row named cve

#>

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
