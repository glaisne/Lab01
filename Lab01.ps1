$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = "*"
            PSDscAllowPlainTextPassword = $True
            MaximumMemory               = 4GB
            MinimumMemory               = 1GB
            SecureBoot                  = $True
            RestartIfNeeded             = $True
            VMRootFolder = "C:\VMs"
        },
        @{
            NodeName = 'Localhost'
            Role = 'HyperVServer'
        },
        @{
            NodeName = 'Server01'
            Role = 'StandAlone'
        }
    )
}



configuration Lab01
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    import-DscResource -ModuleName xHyper-V

    Node $AllNodes.Where{$_.role -contains 'HyperVServer'}.NodeName
    {
        WindowsFeature HyperV
        {
            Name                 = 'Hyper-V'
            Ensure               = 'Present'
            IncludeAllSubFeature = $True
        }

        WindowsFeature RSATHyperVTools
        {
            Name                 = 'RSAT-Hyper-V-Tools'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true
            DependsOn            = '[WindowsFeature]HyperV'
        }

        xVMSwitch InternalSwitch
        {
            Name      = 'Switch-Internal'
            Ensure    = 'Present'
            type      = 'Internal'
            DependsOn = '[WindowsFeature]HyperV'
        }

        xVMSwitch ExternalSwitch
        {
            Name              = 'Switch-External'
            Ensure            = 'Present'
            type              = 'External'
            AllowManagementOS = $True
            DependsOn         = '[WindowsFeature]HyperV'
            NetAdapterName    = 'Wi-Fi'
        }
    }


    Node $AllNodes.Where{$_.Role -contains 'StandAlone'}.NodeName
    {
    
        File "DestinationFolder VMFolder"
        {
            DestinationPath = "$($Node.VMRootFolder)\$($Node.NodeName)\"
            type            = 'Directory'
            Ensure          = 'Present'
        }

        #
        # The Base Eval image needs to be setup in EUFI format
        # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
        # or, do as I did. Run an install of 2016 in a VM
        # then overwrite the VM with the Install.WIM
        File "CopyBaseImage"
        {
            SourcePath      = "$($Node.VMRootFolder)\Base\Server2016\2016EvalGui.vhdx"
            DestinationPath = "$($Node.VMRootFolder)\$($Node.NodeName)\$($Node.NodeName).vhdx"
            DependsOn       = "[File]DestinationFolder VMFolder"
        }
    


        #
        # CopyUnattendedXml requires 
        # Use-WindowsUnattend -Path 'H:\' -UnattendPath $($Node.VMRootFolder)\Sysprep\Unattend.xml
        # run on the base image
        xVhdFile "CopyUnattendedXml"
        {
            VhdPath       = "$($Node.VMRootFolder)\$($Node.NodeName)\$($Node.NodeName)`.vhdx"
            FileDirectory = @(MSFT_xFileDirectory
                {
                    SourcePath      = "$($Node.VMRootFolder)\Lab01\Sysprep\2016DataCenterEval_2.xml"
                    DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
                }
                MSFT_xFileDirectory
                {
                    SourcePath      = "$($Node.VMRootFolder)\Lab01\$($Node.NodeName)\Localhost.mof"
                    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
                    type            = 'File'
                }

                # Pending.Meta.mof
                MSFT_xFileDirectory
                {
                    SourcePath      = "$($Node.VMRootFolder)\Lab01\$($Node.NodeName)\Localhost.meta.mof"
                    DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
                    force           = $True

                }

                # xComputerMangement
                MSFT_xFileDirectory
                {
                    SourcePath      = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type            = 'Directory'
                    Recurse         = $True
                }

                # xNetworking
                MSFT_xFileDirectory
                {
                    SourcePath      = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\'
                    DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
                    type            = 'Directory'
                    Recurse         = $True
                }
            )
            DependsOn     = "[File]CopyBaseImage"
    
        }


        xVMHyperv "Create Server"
        {
            Name            = $($Node.NodeName)
            VHDPath         = "$($Node.VMRootFolder)\$($Node.NodeName)\$($Node.NodeName)`.vhdx"
            DependsOn       = "[File]CopyBaseImage", "[xVhdFile]CopyUnattendedXml" #, '[xVMSwitch]InternalSwitch'
            Ensure          = 'Present'
            Generation      = 2
            MaximumMemory   = $Node.MaximumMemory
            MinimumMemory   = $Node.MinimumMemory
            StartupMemory   = 2GB
            State           = 'Running'
            SecureBoot      = $Node.SecureBoot
            SwitchName      = 'Switch-Internal', 'Switch-External'
            RestartIfNeeded = $Node.RestartIfNeeded
        }
    }
    
    #     #
    #     #  DC01
    #     #


    #     File "DestinationFolder DC01"
    #     {
    #         DestinationPath = "$($Node.VMRootFolder)\DC01\"
    #         type            = 'Directory'
    #         Ensure          = 'Present'
    #     }

    #     #
    #     # The Base Eval image needs to be setup in EUFI format
    #     # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
    #     # or, do as I did. Run an install of 2016 in a VM
    #     # then overwrite the VM with the Install.WIM
    #     File "CopyBaseImage DC01"
    #     {
    #         SourcePath = '$($Node.VMRootFolder)\Base\Server2016\2016EvalGui.vhdx'
    #         DestinationPath = "$($Node.VMRootFolder)\DC01\DC01.vhdx"
    #         DependsOn = "[File]DestinationFolder DC01"
    #     }

    #     #
    #     # CopyUnattendedXml requires 
    #     # Use-WindowsUnattend -Path 'H:\' -UnattendPath $($Node.VMRootFolder)\Sysprep\Unattend.xml
    #     # run on the base image
    #     xVhdFile "CopyUnattendedXml DC01"
    #     {
    #         VhdPath =  "$($Node.VMRootFolder)\DC01\DC01`.vhdx"
    #         FileDirectory =  @(

    #             # Pending.mof
    #             #MSFT_xFileDirectory {
    #             #    DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
    #             #    Ensure = 'Absent'
    #             #}

    #             # Pending.mof
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\ForestRoot\Localhost.mof'
    #                 DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
    #                 force           = $True

    #             }

    #             # Pending.Meta.mof
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\ForestRoot\Localhost.meta.mof'
    #                 DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
    #                 force           = $True

    #             }
            
    #             # unattend.xml
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
    #                 DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
    #                 force           = $True
    #             }

    #             # xActiveDirectory
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #             # xNetworking
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #             # xComputerMangement
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #             # xComputerMangement
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xPendingReboot\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }
    #         )
    #         DependsOn = "[File]CopyBaseImage DC01"
    #     }
    

    #     xVMHyperv "Create DC01"
    #     {
    #         Name = 'DC01'
    #         VHDPath = "$($Node.VMRootFolder)\DC01\DC01.vhdx"
    #         DependsOn = "[File]CopyBaseImage DC01","[xVhdFile]CopyUnattendedXml DC01", '[xVMSwitch]InternalSwitch'
    #         Ensure = 'Present'
    #         Generation = 2
    #         MaximumMemory = $Node.MaximumMemory
    #         MinimumMemory = $Node.MinimumMemory
    #         StartupMemory = 2GB
    #         State = 'Running'
    #         SecureBoot = $Node.SecureBoot
    #         SwitchName = 'Switch-Internal'
    #         RestartIfNeeded = $Node.RestartIfNeeded
    #     }


    #     #
    #     #  DC02
    #     #


    #     File "DestinationFolder DC02"
    #     {
    #         DestinationPath = "$($Node.VMRootFolder)\DC02\"
    #         type            = 'Directory'
    #         Ensure          = 'Present'
    #     }

    #     #
    #     # The Base Eval image needs to be setup in EUFI format
    #     # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
    #     # or, do as I did. Run an install of 2016 in a VM
    #     # then overwrite the VM with the Install.WIM
    #     File "CopyBaseImage DC02"
    #     {
    #         SourcePath = '$($Node.VMRootFolder)\Base\Server2016\2016EvalGui.vhdx'
    #         DestinationPath = "$($Node.VMRootFolder)\DC02\DC02.vhdx"
    #         DependsOn = "[File]DestinationFolder DC02"
    #     }

    #     #
    #     # CopyUnattendedXml requires 
    #     # Use-WindowsUnattend -Path 'H:\' -UnattendPath $($Node.VMRootFolder)\Sysprep\Unattend.xml
    #     # run on the base image
    #     xVhdFile "CopyUnattendedXml DC02"
    #     {
    #         VhdPath =  "$($Node.VMRootFolder)\DC02\DC02`.vhdx"
    #         FileDirectory =  @(

    #             # Pending.mof
    #             MSFT_xFileDirectory {
    #                 DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
    #                 Ensure = 'Absent'
    #             }

    #             # Pending.mof
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\DC02\Localhost.mof'
    #                 DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
    #                 force           = $True

    #             }

    #             # Pending.Meta.mof
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\DC02\Localhost.meta.mof'
    #                 DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
    #                 force           = $True

    #             }
            
    #             # unattend.xml
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
    #                 DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
    #             }

    #             # xActiveDirectory
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #             # xNetworking
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #             # xComputerMangement
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #             # xComputerMangement
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xPendingReboot\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }
    #         )
    #         DependsOn = "[File]CopyBaseImage DC02"
    #     }


    #     xVMHyperv "Create DC02"
    #     {
    #         Name = 'DC02'
    #         VHDPath = "$($Node.VMRootFolder)\DC02\DC02`.vhdx"
    #         DependsOn = "[File]CopyBaseImage DC02","[xVhdFile]CopyUnattendedXml DC02", '[xVMSwitch]InternalSwitch'
    #         Ensure = 'Present'
    #         Generation = 2
    #         MaximumMemory = $Node.MaximumMemory
    #         MinimumMemory = $Node.MinimumMemory
    #         StartupMemory = 2GB
    #         State = 'Running'
    #         SecureBoot = $Node.SecureBoot
    #         SwitchName = 'Switch-Internal'
    #         RestartIfNeeded = $Node.RestartIfNeeded
    #     }


    #     #
    #     #  App01
    #     #

   
    #     File "DestinationFolder App01"
    #     {
    #         DestinationPath = "$($Node.VMRootFolder)\App01\"
    #         type            = 'Directory'
    #         Ensure          = 'Present'
    #     }

    #     #
    #     # The Base Eval image needs to be setup in EUFI format
    #     # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
    #     # or, do as I did. Run an install of 2016 in a VM
    #     # then overwrite the VM with the Install.WIM
    #     File "CopyBaseImage App01"
    #     {
    #         SourcePath = '$($Node.VMRootFolder)\Base\Server2016\2016EvalGui.vhdx'
    #         DestinationPath = "$($Node.VMRootFolder)\App01\App01.vhdx"
    #         DependsOn = "[File]DestinationFolder App01"
    #     }
    


    #     #
    #     # CopyUnattendedXml requires 
    #     # Use-WindowsUnattend -Path 'H:\' -UnattendPath $($Node.VMRootFolder)\Sysprep\Unattend.xml
    #     # run on the base image
    #     xVhdFile "CopyUnattendedXml App01"
    #     {
    #         VhdPath =  "$($Node.VMRootFolder)\App01\App01`.vhdx"
    #         FileDirectory =  @(
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\Sysprep\2016DataCenterEval_2.xml'
    #                 DestinationPath = "\Windows\System32\Sysprep\Unattend.xml"
    #             }

    #             # xComputerMangement
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xComputerManagement\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #             # Pending.mof
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\App01\Localhost.mof'
    #                 DestinationPath = "\Windows\System32\Configuration\Pending.mof" 
    #                 force           = $True

    #             }

    #             # Pending.Meta.mof
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\App01\Localhost.meta.mof'
    #                 DestinationPath = "\Windows\System32\Configuration\metaconfig.mof" 
    #                 force           = $True

    #             }

    #             # xNetworking
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #             # xActiveDirectory
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\'
    #                 DestinationPath = "\Program Files\WindowsPowerShell\Modules\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #         <#
    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\App01\Sources\'
    #                 DestinationPath = "\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\App01\WebSite\'
    #                 DestinationPath = "\WebSite\" 
    #                 type    = 'Directory'
    #                 Recurse = $True
    #             }

    #             MSFT_xFileDirectory {
    #                 SourcePath = 'F:\DSCScripts\Lab01\App01\scripts\'
    #                 DestinationPath = "\Scripts\"
    #                 type = 'directory'
    #                 Ensure = 'Present'
    #             }
    #         #>
    #         )
    #         DependsOn = "[File]CopyBaseImage App01"
    
    #     }


    #     xVMHyperv "Create App01"
    #     {
    #         Name = 'App01'
    #         VHDPath = "$($Node.VMRootFolder)\App01\App01`.vhdx"
    #         DependsOn = "[File]CopyBaseImage App01","[xVhdFile]CopyUnattendedXml App01" , '[xVMSwitch]InternalSwitch'
    #         Ensure = 'Present'
    #         Generation = 2
    #         MaximumMemory = $Node.MaximumMemory
    #         MinimumMemory = $Node.MinimumMemory
    #         StartupMemory = 1GB
    #         State = 'Running'
    #         SecureBoot = $Node.SecureBoot
    #         SwitchName = 'Switch-Internal'
    #         RestartIfNeeded = $Node.RestartIfNeeded
    #     }
    # }
}

Lab01  -ConfigurationData $ConfigurationData