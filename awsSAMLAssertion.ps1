using namespace System.Net
using namespace System.Net.Http
using namespace System.Text
using namespace System.IO
using namespace System.Xml
using namespace System.Text.RegularExpressions
using namespace System.Collections.Generic
using namespace System.Collections

class AWSRole {
    [string]$roleArn  
    [string]$principalArn
    $Assertion

    AWSRole($r, $a) {
        $this.roleArn = $r.Split(",")[0]
        $this.principalArn = $r.Split(",")[1]
        $this.Assertion = $a
    }
}
function Get-AWSRole {
    param (
        $SAMLResponse
    )
    [ArrayList]$AWSRoles = @()
    $SAMLAssertionString = [Encoding]::UTF8.GetString([Convert]::FromBase64String($SAMLResponse))
    $SAMLAssertionXMLDoc = [XmlDocument]::new()
    $SAMLAssertionXMLDoc.LoadXml($SAMLAssertionString);
    $SAMLAttributeValues = ($SAMLAssertionXMLDoc.Response.Assertion.AttributeStatement.Attribute | `
                Where-Object {$_.Name -eq "https://aws.amazon.com/SAML/Attributes/Role"}).AttributeValue | Select-Object `#text

    foreach ($role in $SAMLAttributeValues) {
        $role
        [void]$AWSRoles.Add($role.'#text')
    }

    if ($AWSRoles.Count -eq 1) {
        
        return [AWSRole]::new($AWSRoles[0], $SAMLResponse)
        
    }
    
    while ($true) {
        Clear-Host
        Write-Host "Please choose the role you would like to assume:`n" -ForegroundColor Yellow 
        if ($AWSRoles.Count -gt 1){
            $index = 1
            foreach ($role in $AWSRoles) {
                $r = ($role.Split(","))[0]
                Write-Host -NoNewline -ForegroundColor Green "[ $index ]"; Write-Host " $r"
                $index ++
            }

            $userSelectedRole = Read-Host
            if ($userSelectedRole -gt $AWSRoles.Count){
                Clear-Host
                Write-Host -NoNewline -ForegroundColor Yellow "[+]"; Write-Host " You selected an invalid role index, please try again " -ForegroundColor Red
                start-Sleep 3
                continue
            }
            
            return [AWSRole]::new($AWSRoles[$userSelectedRole - 1], $SAMLResponse)
        }
    }
    
}

function Get-SAMLAssertion {
    # uris
    $idpentryurl = 'HERE'
    $ssologinurl = 'HERE'


    # Get auth token to pass to aws 
    $response = Invoke-WebRequest -Uri $ssologinurl -Method POST -UseDefaultCredentials 
    $token = ($response.Content | ConvertFrom-Json).tokenId
    $uri = [uri]::new($idpentryurl)

    $request = [HttpWebRequest][WebRequest]::Create($uri)
    $request.Method = "GET"
    $request.UserAgent = "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; WOW64; Trident/6.0)"
    $request.KeepAlive = $true
    $request.PreAuthenticate = $false
    $request.AllowAutoRedirect = $true
    $request.CookieContainer = [System.Net.CookieContainer]::new()
    $cookie = [system.Net.Cookie]::new("HERE", $token)
    $request.CookieContainer.Add($uri,$cookie)

    $response = [HttpWebResponse]$request.GetResponse()

    $reader = [StreamReader]::new($response.GetResponseStream())
    $responseStreamData = $reader.ReadToEnd()
    $XMLDoc = [XmlDocument]::new()
    $XMLDoc.LoadXml($responseStreamData);
    $SAMLResponse = $XMLDoc.html.body.form.input.value
    if (!$SAMLResponse) {
        Clear-Host
        write-Host -NoNewline [+] -ForegroundColor Yellow ; Write-Host -ForegroundColor Red " Something went wrong during authentication."
        exit
    }
    return $SAMLResponse
}

## Deserialize and serialize this using export/importvli-xml for automation or moving across session boundary
$cred = Get-AWSRole -SAMLResponse (Get-SAMLAssertion)


$o = Use-STSRoleWithSAML -RoleArn $creds.roleArn `
                            -PrincipalArn $creds.principalArn `
                            -SAMLAssertion $creds.Assertion `
                            -Region "us-east-1"

# Creates and stores profile as the default so -profile does not need to be explicitly provided
Set-AWSCredential `
                  -AccessKey $o.Credentials.AccessKeyId `
                 -SecretKey $o.Credentials.SecretAccessKey `
                 -StoreAs "default" `
                 -SessionToken $o.Credentials.SessionToken `
                 -ProfileLocation "$env:USERPROFILE\.aws\credentials" 
