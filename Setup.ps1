
$NeededDSCResources = @('xHyper-V', 'xActiveDirectory', 'xNetworking', 'xComputerManagement', 'xPendingReboot')

foreach ($DSCResource in $NeededDSCResources)
{
    if (get-module $DSCResource -ListAvailable -ea 0)
    {
        try
        {
            import-module MSOnline -ErrorAction Stop
        }
        catch
        {
            $err = $err
            Write-Error "Unable to load module MSOnline.`nSee https://technet.microsoft.com/library/dn975125.aspx`n$($err.exception.message)"
        }
    }
    else
    {
        install-module $DSCResource
    }
}

function Replace-InFile() 
{
    param
    (
        [string] $Path, 
        [regex] $Find, 
        [string] $Replace
    )
    if (-not (test-path $path -ea 0))
    {
        Write-Error "Access denied $path"
        return
    }

    $Content = (Get-Content $path)
    $content -replace $find.tostring(), $replace | Set-Content $path
}

foreach ($DSCResource in $NeededDSCResources)
{
    $Module = get-module $DSCResource -ListAvailable  |sort version -desc | select -first 1

    $importModuleLine = "    Import-DscResource -ModuleName @`{{ModuleName=""{0}"";ModuleVersion=""{1}""`}}" -f $module.Name, $module.Version.tostring()

    dir *.ps1 -recurse | % {Replace-InFile -Path $_.FullName -Find "^ *import-DscResource\s*-ModuleName.*$DSCResource.*$" -Replace $importModuleLine}

    # SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\2.16.0.0\.16.0.0\
    dir *.ps1 -recurse | % {Replace-InFile -Path $_.FullName -Find "C:\\Program Files\\WindowsPowerShell\\Modules\\$DSCResource\\[a-z0-9-_]*" -Replace "$(split-path $module.path)\"}
}

