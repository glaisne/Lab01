<<<<<<< HEAD
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = "Localhost"
            PSDscAllowPlainTextPassword = $True
            MaximumMemory               = 4GB
            MinimumMemory               = 1GB
            SecureBoot                  = $True
            RestartIfNeeded             = $True
        }
    )
}



configuration Lab01
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName @{ModuleName="xHyper-V";ModuleVersion="3.16.0.0"}

    Node Localhost
    {
    
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
            DestinationPath = "C:\VMs\WSUS01\"
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
            SourcePath = "C:\VMs\Base\Server2016\2016EvalGui.vhdx"
            DestinationPath = "C:\VMs\WSUS01\WSUS01.vhdx"
            DependsOn = "[File]DestinationFolder WSUS01"
        }
    


        #
        # CopyUnattendedXml requires 
        # Use-WindowsUnattend -Path 'H:\' -UnattendPath C:\VMs\Sysprep\Unattend.xml
        # run on the base image
        xVhdFile "CopyUnattendedXml WSUS01"
        {
            VhdPath =  "C:\VMs\WSUS01\WSUS01`.vhdx"
            FileDirectory =  @(MSFT_xFileDirectory {
                    SourcePath ='C:\Users\GLaisne\OneDrive - Carbonite\PowerShell\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
                    DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
                }
                MSFT_xFileDirectory {
                    SourcePath = 'F:\DSCScripts\Lab01\WSUS01\Localhost.mof'
                    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                    type    = 'File'
                }

                # Pending.Meta.mof
                MSFT_xFileDirectory {
                    SourcePath = 'F:\DSCScripts\Lab01\WSUS01\Localhost.meta.mof'
                    DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
                    force           = $True

                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\3.1.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # PoshWSUS
                MSFT_xFileDirectory {
                    SourcePath = 'F:\repositories\PoshWSUS\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xNetworking
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\5.3.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }
            )
            DependsOn = "[File]CopyBaseImage WSUS01"
    
        }


        xVMHyperv "Create WSUS01"
        {
            Name            = 'WSUS01'
            VHDPath         = "C:\VMs\WSUS01\WSUS01`.vhdx"
            DependsOn       = "[File]CopyBaseImage WSUS01","[xVhdFile]CopyUnattendedXml WSUS01", '[xVMSwitch]InternalSwitch'
            Ensure          = 'Present'
            Generation      = 2
            MaximumMemory   = $Node.MaximumMemory
            MinimumMemory   = $Node.MinimumMemory
            StartupMemory   = 2GB
            State           = 'Running'
            SecureBoot      = $Node.SecureBoot
            SwitchName      = 'Switch-Internal','Switch-External'
            RestartIfNeeded = $Node.RestartIfNeeded
        }

    
        #
        #  DC01
        #


        File "DestinationFolder DC01"
        {
            DestinationPath = "C:\VMs\DC01\"
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
            SourcePath = "C:\VMs\Base\Server2016\2016EvalGui.vhdx"
            DestinationPath = "C:\VMs\DC01\DC01.vhdx"
            DependsOn = "[File]DestinationFolder DC01"
        }

        #
        # CopyUnattendedXml requires 
        # Use-WindowsUnattend -Path 'H:\' -UnattendPath C:\VMs\Sysprep\Unattend.xml
        # run on the base image
        xVhdFile "CopyUnattendedXml DC01"
        {
            VhdPath =  "C:\VMs\DC01\DC01`.vhdx"
            FileDirectory =  @(

                # Pending.mof
                #MSFT_xFileDirectory {
                #    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                #    Ensure = 'Absent'
                #}

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
                    SourcePath ='C:\Users\GLaisne\OneDrive - Carbonite\PowerShell\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
                    DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
                    force           = $True
                }

                # xActiveDirectory
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\2.16.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xNetworking
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\5.3.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\3.1.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xPendingReboot\0.3.0.0\'
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
            VHDPath = "C:\VMs\DC01\DC01.vhdx"
            DependsOn = "[File]CopyBaseImage DC01","[xVhdFile]CopyUnattendedXml DC01", '[xVMSwitch]InternalSwitch'
            Ensure = 'Present'
            Generation = 2
            MaximumMemory = $Node.MaximumMemory
            MinimumMemory = $Node.MinimumMemory
            StartupMemory = 2GB
            State = 'Running'
            SecureBoot = $Node.SecureBoot
            SwitchName = 'Switch-Internal'
            RestartIfNeeded = $Node.RestartIfNeeded
        }


        #
        #  DC02
        #


        File "DestinationFolder DC02"
        {
            DestinationPath = "C:\VMs\DC02\"
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
            SourcePath = "C:\VMs\Base\Server2016\2016EvalGui.vhdx"
            DestinationPath = "C:\VMs\DC02\DC02.vhdx"
            DependsOn = "[File]DestinationFolder DC02"
        }

        #
        # CopyUnattendedXml requires 
        # Use-WindowsUnattend -Path 'H:\' -UnattendPath C:\VMs\Sysprep\Unattend.xml
        # run on the base image
        xVhdFile "CopyUnattendedXml DC02"
        {
            VhdPath =  "C:\VMs\DC02\DC02`.vhdx"
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
                    SourcePath ='C:\Users\GLaisne\OneDrive - Carbonite\PowerShell\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
                    DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
                    force           = $True
                }

                # xActiveDirectory
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\2.16.0.0\xActiveDirectory\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xNetworking
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\5.3.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\3.1.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xPendingReboot\0.3.0.0\'
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
            VHDPath = "C:\VMs\DC02\DC02`.vhdx"
            DependsOn = "[File]CopyBaseImage DC02","[xVhdFile]CopyUnattendedXml DC02", '[xVMSwitch]InternalSwitch'
            Ensure = 'Present'
            Generation = 2
            MaximumMemory = $Node.MaximumMemory
            MinimumMemory = $Node.MinimumMemory
            StartupMemory = 2GB
            State = 'Running'
            SecureBoot = $Node.SecureBoot
            SwitchName = 'Switch-Internal'
            RestartIfNeeded = $Node.RestartIfNeeded
        }


        #
        #  App01
        #

   
        File "DestinationFolder App01"
        {
            DestinationPath = "C:\VMs\App01\"
            type            = 'Directory'
            Ensure          = 'Present'
        }

        #
        # The Base Eval image needs to be setup in EUFI format
        # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
        # or, do as I did. Run an install of 2016 in a VM
        # then overwrite the VM with the Install.WIM
        File "CopyBaseImage App01"
        {
            SourcePath = "C:\VMs\Base\Server2016\2016EvalGui.vhdx"
            DestinationPath = "C:\VMs\App01\App01.vhdx"
            DependsOn = "[File]DestinationFolder App01"
        }
    


        #
        # CopyUnattendedXml requires 
        # Use-WindowsUnattend -Path 'H:\' -UnattendPath C:\VMs\Sysprep\Unattend.xml
        # run on the base image
        xVhdFile "CopyUnattendedXml App01"
        {
            VhdPath =  "C:\VMs\App01\App01`.vhdx"
            FileDirectory =  @(
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Users\GLaisne\OneDrive - Carbonite\PowerShell\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
                    DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
                    force           = $True
                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath      = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\3.1.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type            = 'Directory'
                    Recurse         = $True
                }

                # Pending.mof
                MSFT_xFileDirectory {
                    SourcePath      = 'F:\DSCScripts\Lab01\App01\Localhost.mof'
                    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                    force           = $True

                }

                # Pending.Meta.mof
                MSFT_xFileDirectory {
                    SourcePath      = 'F:\DSCScripts\Lab01\App01\Localhost.meta.mof'
                    DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
                    force           = $True

                }

                # xNetworking
                MSFT_xFileDirectory {
                    SourcePath      = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\5.3.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type            = 'Directory'
                    Recurse         = $True
                }

                # xActiveDirectory
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\2.16.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

            <#
                MSFT_xFileDirectory {
                    SourcePath = 'F:\DSCScripts\Lab01\App01\Sources\'
                    DestinationPath = "\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                MSFT_xFileDirectory {
                    SourcePath = 'F:\DSCScripts\Lab01\App01\WebSite\'
                    DestinationPath = "\WebSite\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                MSFT_xFileDirectory {
                    SourcePath = 'F:\DSCScripts\Lab01\App01\scripts\'
                    DestinationPath = "\Scripts\"
                    type = 'directory'
                    Ensure = 'Present'
                }
            #>
            )
            DependsOn = "[File]CopyBaseImage App01"
    
        }


        xVMHyperv "Create App01"
        {
            Name = 'App01'
            VHDPath = "C:\VMs\App01\App01`.vhdx"
            DependsOn = "[File]CopyBaseImage App01","[xVhdFile]CopyUnattendedXml App01" , '[xVMSwitch]InternalSwitch'
            Ensure = 'Present'
            Generation = 2
            MaximumMemory = $Node.MaximumMemory
            MinimumMemory = $Node.MinimumMemory
            StartupMemory = 1GB
            State = 'Running'
            SecureBoot = $Node.SecureBoot
            SwitchName = 'Switch-Internal'
            RestartIfNeeded = $Node.RestartIfNeeded
        }
    }
}

Lab01  -ConfigurationData $ConfigurationData
=======
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = "Localhost"
            PSDscAllowPlainTextPassword = $True
            MaximumMemory               = 4GB
            MinimumMemory               = 1GB
            SecureBoot                  = $True
            RestartIfNeeded             = $True
        }
    )
}



configuration Lab01
{
    param (
        $RootFolder = 'C:\github\lab01'
    )

    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName @{ModuleName="xHyper-V";ModuleVersion="3.12.0.0"}

    Node Localhost
    {
    
        # WindowsFeature HyperV
        # {
        #     Name = 'Hyper-V'
        #     Ensure = 'Present'
        #     IncludeAllSubFeature = $True
        # }

        # WindowsFeature RSATHyperVTools
        # {
        #     Name = 'RSAT-Hyper-V-Tools'
        #     Ensure = 'Present'
        #     IncludeAllSubFeature = $true
        #     DependsOn = '[WindowsFeature]HyperV'
        # }

        # xVMSwitch InternalSwitch
        # {
        #     Name = 'Switch-Internal'
        #     Ensure = 'Present'
        #     type = 'Internal'
        #     DependsOn = '[WindowsFeature]HyperV'
        # }

        # xVMSwitch ExternalSwitch
        # {
        #     Name = 'Switch-External'
        #     Ensure = 'Present'
        #     type = 'External'
        #     AllowManagementOS = $True
        #     DependsOn = '[WindowsFeature]HyperV'
        #     NetAdapterName = 'Wi-Fi'
        # }


        #
        #  WSUS01
        #

    
        File "DestinationFolder WSUS01"
        {
            DestinationPath = "C:\VMs\WSUS01\"
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
            SourcePath = "C:\VMs\Source\Base\Server2016\2016EvalGui.vhdx"
            DestinationPath = "C:\VMs\WSUS01\WSUS01.vhdx"
            DependsOn = "[File]DestinationFolder WSUS01"
        }
    


        #
        # CopyUnattendedXml requires 
        # Use-WindowsUnattend -Path 'H:\' -UnattendPath C:\VMs\Sysprep\Unattend.xml
        # run on the base image
        xVhdFile "CopyUnattendedXml WSUS01"
        {
            VhdPath =  "C:\VMs\WSUS01\WSUS01`.vhdx"
            FileDirectory =  @(MSFT_xFileDirectory {
                    SourcePath ='C:\Users\GLaisne\OneDrive - Carbonite\PowerShell\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
                    DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
                }
                MSFT_xFileDirectory {
                    SourcePath = "$RootFolder\WSUS01\Localhost.mof"
                    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                    type    = 'File'
                }

                # Pending.Meta.mof
                MSFT_xFileDirectory {
                    SourcePath = "$RootFolder\WSUS01\Localhost.meta.mof"
                    DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
                    force           = $True

                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\4.1.0.0\.1.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # PoshWSUS
                MSFT_xFileDirectory {
                    SourcePath = 'F:\repositories\PoshWSUS\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xNetworking
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\5.7.0.0\.3.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }
            )
            DependsOn = "[File]CopyBaseImage WSUS01"
    
        }


        xVMHyperv "Create WSUS01"
        {
            Name            = 'WSUS01'
            VHDPath         = "C:\VMs\WSUS01\WSUS01`.vhdx"
            DependsOn       = "[File]CopyBaseImage WSUS01","[xVhdFile]CopyUnattendedXml WSUS01" #, '[xVMSwitch]InternalSwitch'
            Ensure          = 'Present'
            Generation      = 2
            MaximumMemory   = $Node.MaximumMemory
            MinimumMemory   = $Node.MinimumMemory
            StartupMemory   = 2GB
            State           = 'Running'
            SecureBoot      = $Node.SecureBoot
            SwitchName      = 'Switch-Internal','Switch-External'
            RestartIfNeeded = $Node.RestartIfNeeded
        }

    
        #
        #  DC01
        #


        File "DestinationFolder DC01"
        {
            DestinationPath = "C:\VMs\DC01\"
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
            SourcePath = "C:\VMs\Source\Base\Server2016\2016EvalGui.vhdx"
            DestinationPath = "C:\VMs\DC01\DC01.vhdx"
            DependsOn = "[File]DestinationFolder DC01"
        }

        #
        # CopyUnattendedXml requires 
        # Use-WindowsUnattend -Path 'H:\' -UnattendPath C:\VMs\Sysprep\Unattend.xml
        # run on the base image
        xVhdFile "CopyUnattendedXml DC01"
        {
            VhdPath =  "C:\VMs\DC01\DC01`.vhdx"
            FileDirectory =  @(

                # Pending.mof
                #MSFT_xFileDirectory {
                #    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                #    Ensure = 'Absent'
                #}

                # Pending.mof
                MSFT_xFileDirectory {
                    SourcePath = "$RootFolder\ForestRoot\Localhost.mof"
                    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                    force           = $True

                }

                # Pending.Meta.mof
                MSFT_xFileDirectory {
                    SourcePath = "$RootFolder\ForestRoot\Localhost.meta.mof"
                    DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
                    force           = $True

                }
            
                # unattend.xml
                MSFT_xFileDirectory {
                    SourcePath ='C:\Users\GLaisne\OneDrive - Carbonite\PowerShell\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
                    DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
                    force           = $True
                }

                # xActiveDirectory
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\2.21.0.0\.16.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xNetworking
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\5.7.0.0\.3.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\4.1.0.0\.1.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xPendingReboot\0.4.0.0\.3.0.0\'
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
            VHDPath = "C:\VMs\DC01\DC01.vhdx"
            DependsOn = "[File]CopyBaseImage DC01","[xVhdFile]CopyUnattendedXml DC01" #, '[xVMSwitch]InternalSwitch'
            Ensure = 'Present'
            Generation = 2
            MaximumMemory = $Node.MaximumMemory
            MinimumMemory = $Node.MinimumMemory
            StartupMemory = 2GB
            State = 'Running'
            SecureBoot = $Node.SecureBoot
            SwitchName = 'Switch-Internal'
            RestartIfNeeded = $Node.RestartIfNeeded
        }


        #
        #  DC02
        #


        File "DestinationFolder DC02"
        {
            DestinationPath = "C:\VMs\DC02\"
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
            SourcePath = "C:\VMs\Source\Base\Server2016\2016EvalGui.vhdx"
            DestinationPath = "C:\VMs\DC02\DC02.vhdx"
            DependsOn = "[File]DestinationFolder DC02"
        }

        #
        # CopyUnattendedXml requires 
        # Use-WindowsUnattend -Path 'H:\' -UnattendPath C:\VMs\Sysprep\Unattend.xml
        # run on the base image
        xVhdFile "CopyUnattendedXml DC02"
        {
            VhdPath =  "C:\VMs\DC02\DC02`.vhdx"
            FileDirectory =  @(

                # Pending.mof
                MSFT_xFileDirectory {
                    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                    Ensure = 'Absent'
                }

                # Pending.mof
                MSFT_xFileDirectory {
                    SourcePath = "$RootFolder\DC02\Localhost.mof"
                    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                    force           = $True

                }

                # Pending.Meta.mof
                MSFT_xFileDirectory {
                    SourcePath = "$RootFolder\DC02\Localhost.meta.mof"
                    DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
                    force           = $True

                }
            
                # unattend.xml
                MSFT_xFileDirectory {
                    SourcePath ='C:\Users\GLaisne\OneDrive - Carbonite\PowerShell\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
                    DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
                    force           = $True
                }

                # xActiveDirectory
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\2.16.0.0\xActiveDirectory\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xNetworking
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\5.7.0.0\.3.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\4.1.0.0\.1.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xPendingReboot\0.4.0.0\.3.0.0\'
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
            VHDPath = "C:\VMs\DC02\DC02`.vhdx"
            DependsOn = "[File]CopyBaseImage DC02","[xVhdFile]CopyUnattendedXml DC02" #, '[xVMSwitch]InternalSwitch'
            Ensure = 'Present'
            Generation = 2
            MaximumMemory = $Node.MaximumMemory
            MinimumMemory = $Node.MinimumMemory
            StartupMemory = 2GB
            State = 'Running'
            SecureBoot = $Node.SecureBoot
            SwitchName = 'Switch-Internal'
            RestartIfNeeded = $Node.RestartIfNeeded
        }


        #
        #  App01
        #

   
        File "DestinationFolder App01"
        {
            DestinationPath = "C:\VMs\App01\"
            type            = 'Directory'
            Ensure          = 'Present'
        }

        #
        # The Base Eval image needs to be setup in EUFI format
        # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
        # or, do as I did. Run an install of 2016 in a VM
        # then overwrite the VM with the Install.WIM
        File "CopyBaseImage App01"
        {
            SourcePath = "C:\VMs\Source\Base\Server2016\2016EvalGui.vhdx"
            DestinationPath = "C:\VMs\App01\App01.vhdx"
            DependsOn = "[File]DestinationFolder App01"
        }
    


        #
        # CopyUnattendedXml requires 
        # Use-WindowsUnattend -Path 'H:\' -UnattendPath C:\VMs\Sysprep\Unattend.xml
        # run on the base image
        xVhdFile "CopyUnattendedXml App01"
        {
            VhdPath =  "C:\VMs\App01\App01`.vhdx"
            FileDirectory =  @(
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Users\GLaisne\OneDrive - Carbonite\PowerShell\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
                    DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
                    force           = $True
                }

                # xComputerMangement
                MSFT_xFileDirectory {
                    SourcePath      = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\4.1.0.0\.1.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type            = 'Directory'
                    Recurse         = $True
                }

                # Pending.mof
                MSFT_xFileDirectory {
                    SourcePath      = "$RootFolder\App01\Localhost.mof"
                    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                    force           = $True

                }

                # Pending.Meta.mof
                MSFT_xFileDirectory {
                    SourcePath      = "$RootFolder\App01\Localhost.meta.mof"
                    DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
                    force           = $True

                }

                # xNetworking
                MSFT_xFileDirectory {
                    SourcePath      = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\5.7.0.0\.3.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type            = 'Directory'
                    Recurse         = $True
                }

                # xActiveDirectory
                MSFT_xFileDirectory {
                    SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\2.21.0.0\.16.0.0\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type    = 'Directory'
                    Recurse = $True
                }

            <#
                MSFT_xFileDirectory {
                    SourcePath = "$RootFolder\App01\Sources\"
                    DestinationPath = "\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                MSFT_xFileDirectory {
                    SourcePath = "$RootFolder\App01\WebSite\"
                    DestinationPath = "\WebSite\" 
                    type    = 'Directory'
                    Recurse = $True
                }

                MSFT_xFileDirectory {
                    SourcePath = "$RootFolder\App01\scripts\"
                    DestinationPath = "\Scripts\"
                    type = 'directory'
                    Ensure = 'Present'
                }
            #>
            )
            DependsOn = "[File]CopyBaseImage App01"
    
        }


        xVMHyperv "Create App01"
        {
            Name = 'App01'
            VHDPath = "C:\VMs\App01\App01.vhdx"
            DependsOn = "[File]CopyBaseImage App01","[xVhdFile]CopyUnattendedXml App01" #, '[xVMSwitch]InternalSwitch'
            Ensure = 'Present'
            Generation = 2
            MaximumMemory = $Node.MaximumMemory
            MinimumMemory = $Node.MinimumMemory
            StartupMemory = 1GB
            State = 'Running'
            SecureBoot = $Node.SecureBoot
            SwitchName = 'Switch-Internal'
            RestartIfNeeded = $Node.RestartIfNeeded
            Path = 'c:\VMs\App01'
        }
    }
}

Lab01  -ConfigurationData $ConfigurationData
>>>>>>> 6d7bfbe223d854e719d4908876925de7d9cd8496
