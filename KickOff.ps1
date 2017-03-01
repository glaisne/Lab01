& $PSScriptRoot\ForestRoot.ps1
& $PSScriptRoot\DC02.ps1
& $PSScriptRoot\WSUS01.ps1
& $PSScriptRoot\App01.ps1
& $PSScriptRoot\Lab01.ps1

$SourcePath = 'F:\VMs\Base\Server2016\2016EvalGui.vhdx'
#        DestinationPath = "F:\VMs\Web01\Web01`.vhdx"

#'dc01','dc02','web01','wsus01' |get-random | % {  write-host -fore cyan $_; Start-Job -ScriptBlock { C:\windows\system32\Robocopy.exe 'F:\VMs\Base\Server2016\' "F:\VMs\$_\" 2016EvalGui.vhdx /j; move "F:\VMs\$_\2016EvalGui.vhdx" "$_`_deleteme.vhdx"} }
#'dc01','dc02','web01','wsus01' | % {  write-host -fore cyan $_; Start-Job -ScriptBlock { C:\windows\system32\Robocopy.exe 'F:\VMs\Base\Server2016\' "F:\VMs\$_\" 2016EvalGui.vhdx /j; move "F:\VMs\$_\2016EvalGui.vhdx" "$_`_deleteme.vhdx"} }

Start-DscConfiguration $PSScriptRoot\Lab01\ -Wait -Verbose -force