function New-SplunkSession {
    param(
        [string]$RootUrl,
        [string]$Username,
        [string]$ApiKey
    )
    $certCallback = @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public class ServerCertificateValidationCallback
{
    public static void Ignore()
    {
        if(ServicePointManager.ServerCertificateValidationCallback ==null)
        {
            ServicePointManager.ServerCertificateValidationCallback += 
                delegate
                (
                    Object obj, 
                    X509Certificate certificate, 
                    X509Chain chain, 
                    SslPolicyErrors errors
                )
                {
                    return true;
                };
        }
    }
}
"@
    Add-Type $certCallback
    [ServerCertificateValidationCallback]::Ignore()
    $creds = @{
        "username" = $Username
        "password" = $ApiKey
    }

    $login_path = "/services/auth/login"
    $content = (Invoke-WebRequest -Uri ($RootUrl + $login_path) -Method Post -Body $creds).Content
    $sessionKeyXMLDoc = [System.Xml.XmlDocument]::new()
    $sessionKeyXMLDoc.LoadXml($content);
    $sessionkey = $sessionKeyXMLDoc.response.sessionKey
    return @{
        "Authorization" = "Splunk $sessionkey"
    }
     
}

function New-SplunkSearchJob {
    param (
        [string]$RootUrl,
        [System.Collections.Hashtable]$SplunkSession,
        [string]$Query
    )

    $searchBody = @{
        search = $Query
    }

    $jobep = "/services/search/jobs"
    $response = (Invoke-WebRequest -Uri ($RootUrl + $jobep) -Method POST -Headers $SplunkSession -Body $searchBody).Content
    $jobIdXMLDoc = [System.Xml.XmlDocument]::new()
    $jobIdXMLDoc.LoadXml($response);
    return $jobIdXMLDoc.response.sid
    
}

function Get-SplunkJobStatus {
    param (
        [string]$RootUrl,
        [string]$JobSid,
        [System.Collections.Hashtable]$SplunkSession

    )

    $jobep = "/services/search/jobs"
    $res = Invoke-WebRequest -Uri ($RootUrl + $jobep + "/" + $JobSid) -Method Get -Headers $SplunkSession
    $jobIdXMLDoc = [System.Xml.XmlDocument]::new()
    $jobIdXMLDoc.LoadXml($res.Content);

    $nsmgr = [System.Xml.XmlNamespaceManager]::new($jobIdXMLDoc.NameTable);
    $nsmgr.AddNamespace("s", "http://dev.splunk.com/ns/rest");
    $status = ($jobIdXMLDoc.SelectNodes("//s:key[@name='dispatchState']", $nsmgr))."#text" 
    if ($status -ne "DONE") {
        return $false
    }
    else {
        return $true
    }
    
}

function Get-SplunkJobResults {
    param(
        [string]$RootUrl,
        [string]$JobSid,
        [System.Collections.Hashtable]$SplunkSession
    )

    $res = (Invoke-WebRequest -Uri ($RootUrl + $jobep + "/" + $JobSid + "/results") -Method Get -Headers $SplunkSession -Body @{"output_mode" = "json"}).Content | ConvertFrom-Json 
    $res.results
}

# Example
$root_url = "https://splunk-api.elsersmusings.com:8089"
$username = "USERNAME_HERE"
$key = "API_KEY_HERE"
$query = @"
search earliest=-14d sourcetype="WinEventLog:Security" EventCode=4776 Logon_Account="bigben" | regex Source_Workstation!="[\"\"'\\\]+"
| stats values(Source_Workstation) as computer
"@

$session = New-SplunkSession -RootUrl $root_url -Username $username -ApiKey $key
$jobSid = New-SplunkSearchJob -RootUrl $root_url -SplunkSession $session -Query $query

while (!(Get-SplunkJobStatus -RootUrl $root_url -JobSid $jobSid -SplunkSession $session)) {
    Start-Sleep -Seconds 3
    continue
}

Get-SplunkJobResults -RootUrl $root_url -JobSid $jobSid -SplunkSession $session
