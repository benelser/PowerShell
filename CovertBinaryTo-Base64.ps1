using namespace System.IO
using namespace System.Text

param (
    [Cmdletbinding()]
    [Parameter(Mandatory=$true)]
    [string]$PathToExe,
    [Parameter(Mandatory=$true)]
    [string]$NewExeName,
    [Parameter(Mandatory=$true)]
    [bool]$Embed
    
)

<#
Demonstrates reading bits and converting to base64 to embed in any tool.
#>
    try {
        $exe = "$env:USERPROFILE\Desktop\$NewExeName.exe"
        $bits = "$env:USERPROFILE\Desktop\$NewExeName.txt"
        $ByteArray = [File]::ReadAllBytes($PathToExe)
        $Base64String = [Convert]::ToBase64String($ByteArray);
        if (!$Embed) {

            [File]::WriteAllBytes($exe, [Convert]::FromBase64String($Base64String))
            Write-host -noNewline "*****" -ForegroundColor Yellow; Write-Host " Your new Exe is ready at $exe " -NoNewline -ForegroundColor Green; Write-host "*****`n`n" -ForegroundColor Yellow;
            explorer "$env:USERPROFILE\Desktop"
            exit
        }

        $Base64String | Out-File $bits
        Write-host -noNewline "*****" -ForegroundColor Yellow; Write-Host " Your new bits are ready at $bits " -NoNewline -ForegroundColor Green; Write-host "*****`n`n" -ForegroundColor Yellow;
$note = @'
Copy your bits in your script and save in a here string like below using the WriteAllBytes Method to write to disk:

$bits = @"
YOUR BITS PASTED HERE
"@

[System.IO.File]::WriteAllBytes('NameOfExe.exe', [Convert]::FromBase64String($bits))

'@
        Write-Host $note -ForegroundColor Yellow;
        notepad.exe $bits
        
    }
    catch {
        Throw "Something went wrong trying to read $PathToExe"
        break
    }
    
