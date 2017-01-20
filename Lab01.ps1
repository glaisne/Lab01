configuration Lab01
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    import-DscResource -ModuleName xHyper-V


    WindowsFeature HyperV
    {
        Name = 'Hyper-V'
        Ensure = 'Present'
        IncludeAllSubFeature = $True
    }

    WindowsFeature RSATHyperVTools
    {
        Name = 'RSAT-Hyper-V-Tools'
        Ensure = 'Present'
        IncludeAllSubFeature = $true
        DependsOn = '[WindowsFeature]HyperV'
    }

    xVMSwitch InternalSwitch
    {
        Name = 'Switch-Internal'
        Ensure = 'Present'
        type = 'Internal'
        DependsOn = '[WindowsFeature]HyperV'
    }

    xVMSwitch ExternalSwitch
    {
        Name = 'Switch-External'
        Ensure = 'Present'
        type = 'External'
        AllowManagementOS = $True
        DependsOn = '[WindowsFeature]HyperV'
        NetAdapterName = 'Wi-Fi'
    }


    #
    #  WSUS01
    #

    
    File "DestinationFolder WSUS01"
    {
        DestinationPath = "F:\VMs\WSUS01\"
        type            = 'Directory'
        Ensure          = 'Present'
    }

    #
    # The Base Eval image needs to be setup in EUFI format
    # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
    # or, do as I did. Run an install of 2016 in a VM
    # then overwrite the VM with the Install.WIM
    File "CopyBaseImage WSUS01"
    {
        SourcePath = 'F:\VMs\Base\Server2016\2016EvalGui.vhdx'
        DestinationPath = "F:\VMs\WSUS01\WSUS01`.vhdx"
        DependsOn = "[File]DestinationFolder WSUS01"
    }
    


    #
    # CopyUnattendedXml requires 
    # Use-WindowsUnattend -Path 'H:\' -UnattendPath F:\VMs\Sysprep\Unattend.xml
    # run on the base image
    xVhdFile "CopyUnattendedXml WSUS01"
    {
        VhdPath =  "F:\VMs\WSUS01\WSUS01`.vhdx"
        FileDirectory =  @(MSFT_xFileDirectory {
                SourcePath = 'F:\VMs\Sysprep\2016DataCenterEval_2.xml'
                DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
            }
            MSFT_xFileDirectory {
                SourcePath = 'F:\DSCScripts\WSUS01\ForestRoot\Localhost.mof'
                DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                type    = 'File'
            }
        )
        DependsOn = "[File]CopyBaseImage WSUS01"
    
    }


    xVMHyperv "Create WSUS01"
    {
        Name = 'WSUS01'
        VHDPath = "F:\VMs\WSUS01\WSUS01`.vhdx"
        DependsOn = '[xVMSwitch]InternalSwitch',"[File]CopyBaseImage WSUS01","[xVhdFile]CopyUnattendedXml WSUS01"
        Ensure = 'Present'
        Generation = 2
        MaximumMemory = 2GB
        MinimumMemory = 1GB
        State = 'Running'
        SecureBoot = $False
        SwitchName = 'Switch-Internal','Switch-External'
        RestartIfNeeded = $True
    }

    
    #
    #  DC01
    #


    File "DestinationFolder DC01"
    {
        DestinationPath = "F:\VMs\DC01\"
        type            = 'Directory'
        Ensure          = 'Present'
    }

    #
    # The Base Eval image needs to be setup in EUFI format
    # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
    # or, do as I did. Run an install of 2016 in a VM
    # then overwrite the VM with the Install.WIM
    File "CopyBaseImage DC01"
    {
        SourcePath = 'F:\VMs\Base\Server2016\2016EvalGui.vhdx'
        DestinationPath = "F:\VMs\DC01\DC01`.vhdx"
        DependsOn = "[File]DestinationFolder DC01"
    }

    #
    # CopyUnattendedXml requires 
    # Use-WindowsUnattend -Path 'H:\' -UnattendPath F:\VMs\Sysprep\Unattend.xml
    # run on the base image
    xVhdFile "CopyUnattendedXml DC01"
    {
        VhdPath =  "F:\VMs\DC01\DC01`.vhdx"
        FileDirectory =  @(

            # Pending.mof
            MSFT_xFileDirectory {
                DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                Ensure = 'Absent'
            }

            # Pending.mof
            MSFT_xFileDirectory {
                SourcePath = 'F:\DSCScripts\Lab01\ForestRoot\Localhost.mof'
                DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                force           = $True

            }

            # Pending.Meta.mof
            MSFT_xFileDirectory {
                SourcePath = 'F:\DSCScripts\Lab01\ForestRoot\Localhost.meta.mof'
                DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
                force           = $True

            }
            
            # unattend.xml
            MSFT_xFileDirectory {
                SourcePath = 'F:\VMs\Sysprep\2016DataCenterEval_2.xml'
                DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
            }

            # xActiveDirectory
            MSFT_xFileDirectory {
                SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\'
                DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                type    = 'Directory'
                Recurse = $True
            }

            # xNetworking
            MSFT_xFileDirectory {
                SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\'
                DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                type    = 'Directory'
                Recurse = $True
            }

            # xComputerMangement
            MSFT_xFileDirectory {
                SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\'
                DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                type    = 'Directory'
                Recurse = $True
            }

            # xComputerMangement
            MSFT_xFileDirectory {
                SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xPendingReboot\'
                DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                type    = 'Directory'
                Recurse = $True
            }
        )
        DependsOn = "[File]CopyBaseImage DC01"
    }


    xVMHyperv "Create DC01"
    {
        Name = 'DC01'
        VHDPath = "F:\VMs\DC01\DC01`.vhdx"
        DependsOn = '[xVMSwitch]InternalSwitch',"[File]CopyBaseImage DC01","[xVhdFile]CopyUnattendedXml DC01"
        Ensure = 'Present'
        Generation = 2
        MaximumMemory = 2GB
        MinimumMemory = 1GB
        State = 'Running'
        SecureBoot = $False
        SwitchName = 'Switch-Internal'
        RestartIfNeeded = $True
    }


    #
    #  DC02
    #


    File "DestinationFolder DC02"
    {
        DestinationPath = "F:\VMs\DC02\"
        type            = 'Directory'
        Ensure          = 'Present'
    }

    #
    # The Base Eval image needs to be setup in EUFI format
    # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
    # or, do as I did. Run an install of 2016 in a VM
    # then overwrite the VM with the Install.WIM
    File "CopyBaseImage DC02"
    {
        SourcePath = 'F:\VMs\Base\Server2016\2016EvalGui.vhdx'
        DestinationPath = "F:\VMs\DC02\DC02`.vhdx"
        DependsOn = "[File]DestinationFolder DC02"
    }

    #
    # CopyUnattendedXml requires 
    # Use-WindowsUnattend -Path 'H:\' -UnattendPath F:\VMs\Sysprep\Unattend.xml
    # run on the base image
    xVhdFile "CopyUnattendedXml DC02"
    {
        VhdPath =  "F:\VMs\DC02\DC02`.vhdx"
        FileDirectory =  @(

            # Pending.mof
            MSFT_xFileDirectory {
                DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                Ensure = 'Absent'
            }

            # Pending.mof
            MSFT_xFileDirectory {
                SourcePath = 'F:\DSCScripts\Lab01\DC02\Localhost.mof'
                DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                force           = $True

            }

            # Pending.Meta.mof
            MSFT_xFileDirectory {
                SourcePath = 'F:\DSCScripts\Lab01\DC02\Localhost.meta.mof'
                DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
                force           = $True

            }
            
            # unattend.xml
            MSFT_xFileDirectory {
                SourcePath = 'F:\VMs\Sysprep\2016DataCenterEval_2.xml'
                DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
            }

            # xActiveDirectory
            MSFT_xFileDirectory {
                SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\'
                DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                type    = 'Directory'
                Recurse = $True
            }

            # xNetworking
            MSFT_xFileDirectory {
                SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\'
                DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                type    = 'Directory'
                Recurse = $True
            }

            # xComputerMangement
            MSFT_xFileDirectory {
                SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\'
                DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                type    = 'Directory'
                Recurse = $True
            }

            # xComputerMangement
            MSFT_xFileDirectory {
                SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xPendingReboot\'
                DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                type    = 'Directory'
                Recurse = $True
            }
        )
        DependsOn = "[File]CopyBaseImage DC02"
    }


    xVMHyperv "Create DC02"
    {
        Name = 'DC02'
        VHDPath = "F:\VMs\DC02\DC02`.vhdx"
        DependsOn = '[xVMSwitch]InternalSwitch',"[File]CopyBaseImage DC02","[xVhdFile]CopyUnattendedXml DC02"
        Ensure = 'Present'
        Generation = 2
        MaximumMemory = 2GB
        MinimumMemory = 1GB
        State = 'Running'
        SecureBoot = $False
        SwitchName = 'Switch-Internal'
        RestartIfNeeded = $True
    }


    #
    #  Web01
    #

    
    File "DestinationFolder Web01"
    {
        DestinationPath = "F:\VMs\Web01\"
        type            = 'Directory'
        Ensure          = 'Present'
    }

    #
    # The Base Eval image needs to be setup in EUFI format
    # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
    # or, do as I did. Run an install of 2016 in a VM
    # then overwrite the VM with the Install.WIM
    File "CopyBaseImage Web01"
    {
        SourcePath = 'F:\VMs\Base\Server2016\2016EvalGui.vhdx'
        DestinationPath = "F:\VMs\Web01\Web01`.vhdx"
        DependsOn = "[File]DestinationFolder Web01"
    }
    


    #
    # CopyUnattendedXml requires 
    # Use-WindowsUnattend -Path 'H:\' -UnattendPath F:\VMs\Sysprep\Unattend.xml
    # run on the base image
    xVhdFile "CopyUnattendedXml Web01"
    {
        VhdPath =  "F:\VMs\Web01\Web01`.vhdx"
        FileDirectory =  @(
            MSFT_xFileDirectory {
                SourcePath = 'F:\VMs\Sysprep\2016DataCenterEval_2.xml'
                DestinationPath = "\Windows\System32\Sysprep\Unattend.xml" #'\Windows\System32\Sysprep\Unattend.xml'
            }
<#
            MSFT_xFileDirectory {
                SourcePath = 'F:\DSCScripts\Lab01\Web01\Sources\'
                DestinationPath = "\" 
                type    = 'Directory'
                Recurse = $True
            }

            MSFT_xFileDirectory {
                SourcePath = 'F:\DSCScripts\Lab01\Web01\WebSite\'
                DestinationPath = "\WebSite\" 
                type    = 'Directory'
                Recurse = $True
            }

            MSFT_xFileDirectory {
                SourcePath = 'F:\DSCScripts\Lab01\Web01\scripts\'
                DestinationPath = "\Scripts\"
                type = 'directory'
                Ensure = 'Present'
            }
#>
        )
        DependsOn = "[File]CopyBaseImage Web01"
    
    }


    xVMHyperv "Create Web01"
    {
        Name = 'Web01'
        VHDPath = "F:\VMs\Web01\Web01`.vhdx"
        DependsOn = '[xVMSwitch]InternalSwitch',"[File]CopyBaseImage Web01","[xVhdFile]CopyUnattendedXml Web01"
        Ensure = 'Present'
        Generation = 2
        MaximumMemory = 2GB
        MinimumMemory = 1GB
        State = 'Off'
        SecureBoot = $False
        SwitchName = 'Switch-Internal'
        RestartIfNeeded = $True
    }
}

Lab01 -ConfigurationData .\Lab01_Data.psd1