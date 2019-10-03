<#
.SYNOPSIS
    Attempts to start PS Remoting on remote machine using scheduled task that runs as system or under user provided credentials in pure PowerShell. 
    Other methods exist that do the same things but most leverage psexec or other tools.
.DESCRIPTION
    Assumes appropriate privs and RPC transport are present while attempting to enable PS Remoting. 
.EXAMPLE
    PS C:\> EnablePSRemoting.ps1 -ComputerName Test
    
.INPUTS
    ComputerName
.OUTPUTS
    Status
#>
param(

    [string]$ComputerName

)

function New-ScheduledTask () {

    [CmdletBinding()]

    param (

    [string]$TaskName,
    [string]$Exe,
    [string]$Arguments,
    [datetime]$Time,
    [Parameter(Mandatory=$true)]
    [bool]$System,
    [pscredential]$Credential,
    [object]$CIMSESSION

    )

    if ($System -eq $true) {

        $principle = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue
        $action = New-ScheduledTaskAction `
                            -Execute $Exe `
                            -Argument $Arguments -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue

        $trigger =  New-ScheduledTaskTrigger -At $Time -Once -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue
        $settings = New-ScheduledTaskSettingsSet -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue

        Register-ScheduledTask -CimSession $CIMSESSION -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description $TaskName -Principal $principle -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue
        Start-ScheduledTask -CimSession $CIMSESSION $TaskName -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue
        Unregister-ScheduledTask -CimSession $CIMSESSION -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue

    }

    else {

        if ($Credential -eq $null) {

            throw 'Provide PSCredential'
        }

            else {
                $username =  $Credential.UserName
                $password = $Credential.GetNetworkCredential().Password
                $action = New-ScheduledTaskAction `
                                    -Execute $Exe `
                                    -Argument $Arguments

                $trigger =  New-ScheduledTaskTrigger -At $Time -Once
                $settings = New-ScheduledTaskSettingsSet

            Register-ScheduledTask -CimSession $CIMSESSION -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description $TaskName -User $username -Password $password
            Start-ScheduledTask -CimSession $CIMSESSION $TaskName -AsJob
            Unregister-ScheduledTask -CimSession $CIMSESSION -TaskName $TaskName -Confirm:$false
            }
    }
}

Clear-Host
Write-Host [+] -NoNewline -ForegroundColor Yellow; Write-Host " Attempting To Turn On Several Services..." -ForegroundColor Green

$services = 'WinRM', 'RasAuto', 'RpcLocator', 'RemoteRegistry', 'RemoteAccess'

foreach ($service in $services) {
    $filter = "name='$Service'"
    $SystemService = Get-WmiObject -class win32_service -ComputerName $ComputerName -Filter $filter -ErrorAction SilentlyContinue
    if($SystemService -eq $null)
    {

        Clear-Host
        Write-Host [+] -NoNewline -ForegroundColor Yellow; Write-Host " RPC Access to $ComputerName Could Not Be Established" -ForegroundColor Red
        exit

    }

    $SystemService.StartService() | Out-Null

}

$time = [datetime]::Now
$PowerShellCommand = @"
-command Enable-PSRemoting
"@
$taskname = "EnableRemoteAccess"
$exe = 'powershell.exe'
$session = New-CimSession -ComputerName $ComputerName

Clear-Host
Write-Host [+] -NoNewline -ForegroundColor Yellow; Write-Host " Attempting to turn on PS Remoting.." -ForegroundColor Green

New-ScheduledTask -CIMSESSION $session -Exe $exe -Arguments "$PowerShellCommand" -Time $time -TaskName $taskname -System $true
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$session = $null

do{

    $session = New-PSSession -ComputerName $ComputerName -ErrorAction SilentlyContinue

}until($session -ne $null -or ($sw.Elapsed).Seconds -gt 30)

if(!$session){
 
    Clear-Host
    Write-Host [+] -NoNewline -ForegroundColor Yellow; Write-Host " PS Remoting Could Not Be Enabled" -ForegroundColor Red
    exit

}

clear-Host

$session | Remove-PSSession
Write-Host [+] -NoNewline -ForegroundColor Yellow; Write-Host " PS Remoting on $ComputerName Has Been Enabled" -ForegroundColor Green
