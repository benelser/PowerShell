function Get-GCPResourceHierarchy {
    param(
        [string]$OrganizationId = $Global:OrgId   
    )

    $tree = which tree
    if($null -eq $tree) {
        throw "Tree binary could not be located make sure you have tree installed by running: sudo apt-get install tree -y and try again"
    }
    # get all projects 
    $allProjects = Invoke-GCPAPI -Url "https://cloudasset.googleapis.com/v1/organizations/$($OrganizationId):searchAllResources?&assetTypes=cloudresourcemanager.googleapis.com.Project&pageSize=500&query=state:ACTIVE" `
            -ThrottleLimit 500 `
            -ResponseProperty "results" `
            -GET

    $allProjectsWithAncestry = $allProjects | ForEach-Object -Parallel {
        # Need to inject class into this thread 
        class ProjectAncestory {
            [string]$ProjectName 
            [object]$Ancestors
        }
        $result = Invoke-RestMethod -Uri "https://cloudresourcemanager.googleapis.com/v1/projects/$($_.name.Split("/")[-1]):getAncestry" -Method Post -Headers $using:AuthHeader
        $p = [ProjectAncestory]::new()
        $p.ProjectName = ($_.name.Split("/")[-1]).Split("/")[0]
        $p.Ancestors = $result.ancestor.resourceId
        $p
    } -ThrottleLimit 250

    # Create all the paths
    [System.Collections.ArrayList]$Paths = @()
    foreach ($project in $allProjectsWithAncestry) {
        $count = $project.Ancestors.Count
        $treePath = [System.Text.StringBuilder]::new()
        while ($count -ne -1) {
            if ($project.Ancestors[$count].type -eq "project") {
                [void]$treePath.Append($project.Ancestors[$count].id)
                [void]$treePath.Append("/#$%p")
            }
            if ($project.Ancestors[$count].type -eq "folder") {
                [void]$treePath.Append($Global:Folders[$project.Ancestors[$count].id])  
                [void]$treePath.Append("/")
            }
            if ($project.Ancestors[$count].type -eq "organization") {
                [void]$treePath.Append($Global:DefaultDomainName)
                [void]$treePath.Append("/")
            }
            $count --
        }
        [void]$Paths.Add($treePath.ToString())
    }

    # Make directories
    $currentLocation = Get-Location
    if ((Test-Path -Path "$Global:WorkSpacePath/Hierarchy") -eq $false) {
        New-Item -ItemType Directory -Path "$Global:WorkSpacePath/Hierarchy" -ErrorAction Stop | Out-Null
    }
    Set-Location -Path "$Global:WorkSpacePath/Hierarchy"
    foreach ($path in $paths) {
        try {
            if ($path[-1] -eq "p") {
                New-Item -ItemType File -Path $path.Replace("/#$%p", "/") -ErrorAction Stop -Force | Out-Null
            }
            else {
                New-Item -ItemType Directory -Path $path -ErrorAction Stop | Out-Null
            }
           
        }
        catch {}
        
    }
    # Invoke tree
    Set-Location -Path $currentLocation.Path
    tree -C "$Global:WorkSpacePath/Hierarchy"
}
