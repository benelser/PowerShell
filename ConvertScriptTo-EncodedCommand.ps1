using namespace System.IO
using namespace System.Text

<#
Great for creating download cradle or using to create scheduled tasks using the -encodedCommand param
#>

param (

       [string] $FilePath
)

    try {

       $script = [File]::ReadAllText($FilePath, [Encoding]::UTF8);
       $ByteArray = [Encoding]::Unicode.GetBytes($script)
       $encodedCommand = [Convert]::ToBase64String($ByteArray);
       $encodedCommand | Out-File "$env:USERPROFILE\Desktop\EncodedCommand.txt"
    }

    catch {

       throw "Something went wrong trying to convert $FilePath"
       break
    }

Write-host -noNewline "*****" -ForegroundColor Yellow; Write-Host " Your EncodedCommand is ready in $env:USERPROFILE\Desktop\EncodedCommand.txt " -NoNewline -ForegroundColor Green; Write-host "*****`n`n" -ForegroundColor Yellow;
notepad.exe $env:USERPROFILE\Desktop\EncodedCommand.txt
