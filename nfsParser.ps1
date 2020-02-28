#!/bin/pwsh
param(
    $Path
)

if ([string]::IsNullOrEmpty($Path)) 
{ 
    "Purpose: Process nmap XML output files from NFS script looking for shares.`n(nmap -v -p 111 --script 'nfs*' -iL nfsSystemsOnline.txt -oA nfsoutput.xml)`n"
    "Example: .\nfsParser.ps1 -Path nfsoutput.xml"
        exit 
    if (!(Test-Path $Path)) {
        "Purpose: Process nmap XML output files from NFS script looking for shares.`n(nmap -v -p 111 --script 'nfs*' -iL nfsSystemsOnline.txt -oA nfsoutput.xml)`n"
        "Example: .\nfsParser.ps1 -Path nfsoutput.xml"
        exit 
    }
}

[Reflection.Assembly]::LoadFile("/opt/microsoft/powershell/6/System.Xml.XDocument.dll") | Out-Null
[Reflection.Assembly]::LoadFile("/opt/microsoft/powershell/6/System.Xml.Linq.dll") | Out-Null
[Reflection.Assembly]::LoadFile("/opt/microsoft/powershell/6/netstandard.dll") | Out-Null
$xmldoc = new-object System.XML.XMLdocument
$xmldoc.Load($path)
$xmlsettings = [System.Xml.XmlReaderSettings]::new()
$xmlsettings.ConformanceLevel = [System.Xml.ConformanceLevel]::Fragment
$xmlsettings.IgnoreWhitespace = $true
$xmlsettings.IgnoreComments = $true
$bytes = [system.text.Encoding]::ASCII.GetBytes($xmldoc.nmaprun.host.InnerXml)
$stream = [system.io.MemoryStream]::new($bytes) 
$reader = [System.Xml.XmlReader]::Create($stream, $xmlsettings)
[System.Collections.ArrayList]$computersWithShares = @()
while ($reader.Read()) {
    if (![string]::IsNullOrEmpty($reader.GetAttribute("addr"))) {
        class Computer {
            $Share
            $IPAddress
            
        }
        $computer = [Computer]::new()
        $computer.IPAddress = $reader.GetAttribute("addr")
        $xmlsettings1 = [System.Xml.XmlReaderSettings]::new()
        $xmlsettings1.ConformanceLevel = [System.Xml.ConformanceLevel]::Fragment
        $xmlsettings1.IgnoreWhitespace = $true
        $xmlsettings1.IgnoreComments = $true
        $innerXML = $reader.ReadInnerXml()
        while ([string]::IsNullOrWhiteSpace($innerXML) -or [string]::IsNullOrEmpty($innerXML)) {
            $reader.Read()
            $innerXML = $reader.ReadInnerXml()
        }
        $bytes1 = [system.text.Encoding]::ASCII.GetBytes($innerXML)
        $stream1 = [system.io.MemoryStream]::new($bytes1) 
        $reader1 = [System.Xml.XmlReader]::Create($stream1, $xmlsettings1)
        while ($reader1.Read()) {
            if (![string]::IsNullOrEmpty($reader1.GetAttribute('output'))) {
                $computer.Share = $reader1.GetAttribute('output').trim()
            }
            else {
                $computer.Share = "none"
            }
        }
        [void]$computersWithShares.Add($computer)
    }
}

$computersWithShares | Where-Object {$_.Share -ne "none"} 
