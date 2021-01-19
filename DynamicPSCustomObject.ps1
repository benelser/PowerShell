# Example of creating dynamic object using PSCustomObject with Add-Member
$object = Import-Clixml "C:\Users\benelser\Downloads\object.xml" # This could be any object with properties and values we need
$counter = ($object.Response.Assertion.AttributeStatement.Attribute.Count -1) # The following alogorithm would change based on above object
$dynamicObject = [pscustomobject]@{} # Instantiate empty object
while ($counter -ne 0) {
    foreach ($key in $object.Response.Assertion.AttributeStatement.Attribute[$counter] | Select-Object Name, AttributeValue) {
        $dynamicObject | Add-Member -MemberType NoteProperty -Name  $key.Name -Value $key.AttributeValue.'#text' # This is important to note adding NoteProperties to our object
    }
    
    $counter --
}
