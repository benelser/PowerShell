using namespace System.Net;
using namespace System.Security.Cryptography.X509Certificates;
using namespace System.Xml;

<#
API DOCS: https://developer.cisco.com/docs/axl/#!hello-world-with-curl/hello-world-with-curl
IP : 10.10.0.199
NM : /24
gw: 10.10.0.254
username: test
password: P@55w0rd1
#>

# To ensure hack is reveresed create get and set functions for security policies and security protocols

# [System.Net.ServicePointManager]::SecurityProtocol = "Ssl3"
[System.Net.ServicePointManager]::Expect100Continue = $true
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12


$code = @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;

    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

Add-Type $code -Language CSharp


$CertificatePolicy = [TrustAllCertsPolicy]::new()
    
[System.Net.ServicePointManager]::CertificatePolicy = $CertificatePolicy

$Create = @"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/10.0">
    <soapenv:Header/>
    <soapenv:Body>
        <ns:addUser>
            <user>
                <lastName>Linux</lastName>
                <userid>CoreyL</userid>
                <presenceGroupName uuid="?">Standard Presence group</presenceGroupName>
                <maxDeskPickupWaitTime>10000</maxDeskPickupWaitTime>
                <remoteDestinationLimit>4</remoteDestinationLimit>
            </user>
        </ns:addUser>
    </soapenv:Body>
</soapenv:Envelope>
"@

$Read = @"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/10.0">
  <soapenv:Header/>
  <soapenv:Body>
    <ns:getUser>
         <userid>bonehead</userid>
      </ns:getUser>
  </soapenv:Body>
</soapenv:Envelope>
"@

$Update = @"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/10.0">
    <soapenv:Header/>
    <soapenv:Body>
        <ns:updateUser>
            <userid>CoreyL</userid>
            <lastName>TESTTTY</lastName>
        </ns:updateUser>
    </soapenv:Body>
</soapenv:Envelope>
"@

$Delete = @"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/10.0">
    <soapenv:Header/>
    <soapenv:Body>
        <ns:removeUser>
            <userid>CoreyL</userid>
        </ns:removeUser>
    </soapenv:Body>
</soapenv:Envelope>
"@

$CreateAppUser = @"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/10.0">
    <soapenv:Header/>
    <soapenv:Body>
        <ns:addAppUser sequence="?">
            <appUser>
                <userid>TESTSUPERADMIN</userid>
                <password>P@55w0rd1</password>
                <presenceGroupName uuid="?">Standard Presence group</presenceGroupName>
                <associatedGroups>
                    <userGroup>
                        <name>Standard CCM Super Users</name>
                        <userRoles>
                            <userRole>Standard CCM Admin Users</userRole>
                        </userRoles>
                    </userGroup>
                    <userGroup>
                        <name>Standard Audit Users</name>
                        <userRoles>
                            <userRole>Standard Audit Log Administration</userRole>
                        </userRoles>
                    </userGroup>
                </associatedGroups>
            </appUser>
        </ns:addAppUser>
    </soapenv:Body>
</soapenv:Envelope>
"@

$getAppUser = @"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/10.0">
    <soapenv:Header/>
    <soapenv:Body>
        <ns:getAppUser sequence="?">
                <userid>test</userid>
        </ns:getAppUser>
    </soapenv:Body>
</soapenv:Envelope>
"@

$sql = @"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/10.0">
    <soapenv:Header/>
    <soapenv:Body>
        <ns:executeSQLQuery sequence="?">
           <sql>
           SELECT * FROM applicationuser;
           </sql>
        </ns:executeSQLQuery>
    </soapenv:Body>
</soapenv:Envelope>
"@
function Invoke-CUCMAPI {
    param (
        [string]$AXL
    )

    $rootURI = "https://10.10.0.199:8443/axl/"
    $Credential = (Get-Credential "test")
    $WebRequest = [System.Net.WebRequest]::Create($rootURI) 
    $WebRequest.Method = "POST"
    $WebRequest.ProtocolVersion = [System.Net.HttpVersion]::Version10
    $WebRequest.Headers.Add("SOAPAction","CUCM:DB ver=10.0")
    $WebRequest.ContentType = "text/xml"
    $WebRequest.Credentials = $Credential.GetNetworkCredential()
    $Stream = $WebRequest.GetRequestStream()
    $Body = [byte[]][char[]]$AXL
    $Stream.Write($Body, 0, $Body.Length)
    $WebResponse = $WebRequest.GetResponse()
    $WebResponseStream = $WebResponse.GetResponseStream()
    $StreamReader = [System.IO.StreamReader]::new($WebResponseStream)
    [xml]$ResponeData = $StreamReader.ReadToEnd()
    return $ResponeData
    
}

$responseData = Invoke-CUCMAPI -AXL $Read
$responseData.Envelope.Body.getUserResponse.return.user

$responseData = Invoke-CUCMAPI -AXL $Create
$responseData.Envelope.Body.addUsererResponse.return

$responseData = Invoke-CUCMAPI -AXL $Update
$responseData.Envelope.Body.updateUserResponse.return

$responseData = Invoke-CUCMAPI -AXL $Delete
$responseData.Envelope.Body.removeUserResponse.return

$responseData = Invoke-CUCMAPI -AXL $CreateAppUser
$responseData.Envelope.Body.removeUserResponse.return

$responseData = Invoke-CUCMAPI -AXL $getAppUser
$responseData.Envelope.Body.getAppUserResponse.return.appUser

$responseData = Invoke-CUCMAPI -AXL $sql
$responseData.Envelope.Body.executeSQLQueryResponse.return.row
