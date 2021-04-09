$list = @(1,2,3,3)

function Get-AllThrees {
    param (
        # This is the context of the entity being processed 
        [Parameter(ValueFromPipeline=$true)]
        [object]$num
    )
    # This executes only once // set up stuff
    Begin {
       [System.Collections.ArrayList]$nums = @()
    }
    # This is essentially a implied foreach where we are writing context on 1 object instead of spelling out foreach
    Process {
        if ($num -eq 3) {
            [void]$nums.Add($num)
        }
    }
    # Executes once // tear down stuff
    End {
       $nums
    }
}
