using namespace System.IO

# Create watcher
$fsw = [FileSystemWatcher]::new("C:\SOMEDIRHERE")
$fsw.NotifyFilter = `
[NotifyFilters]::LastAccess, `
[NotifyFilters]::LastWrite, `
[NotifyFilters]::FileName, `
[NotifyFilters]::DirectoryName

# Define handler methods
$handler_OnChanged =
{
    param([object] $source, [FileSystemEventArgs] $e)
        # Show that a file has been created, changed, or deleted.
    $wct = $e.ChangeType;
    [console]::ForegroundColor = [ConsoleColor]::Green
    [Console]::WriteLine("File {0} {1}", $e.FullPath, $wct.ToString());

}

$handler_OnRenamed = 
{
    param([object] $source, [RenamedEventArgs] $e)
    
        $wct = $e.ChangeType;
        [console]::ForegroundColor = [ConsoleColor]::Green
        [Console]::WriteLine("File {0} {2} to {1}", $e.OldFullPath, $e.FullPath, $wct.ToString());
}

# Wire of event handlers
Register-ObjectEvent -InputObject $fsw -EventName Changed -Action $handler_OnChanged
Register-ObjectEvent -InputObject $fsw -EventName Created -Action $handler_OnChanged
Register-ObjectEvent -InputObject $fsw -EventName Deleted -Action $handler_OnChanged
Register-ObjectEvent -InputObject $fsw -EventName Renamed -Action $handler_OnRenamed
