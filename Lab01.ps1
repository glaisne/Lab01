$ServerName = 'Server01'
$MyData = 
@{
    AllNodes = 
    @(
        @{
            NodeName = "DC01"
            Role     = "DomainController"
        },


        @{
            NodeName = "App01"
            Role     = "AppServer"
        },


        @{
            NodeName = "Cli01"
            Role     = "Client"
        }


        @{
            NodeName = "WSUS01"
            Role     = "WSUS"
        }
    );

    NonNodeData = ""   
}


configuration Lab01
{
    import-DscResource -ModuleName xHyper-V
    Import-DscResource -ModuleName PSDesiredStateConfiguration


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

    Node $AllNodes

    xVMSwitch InternalSwitch
    {
        Name = 'Switch-Internal'
        Ensure = 'Present'
        type = 'Internal'
        DependsOn = '[WindowsFeature]HyperV'
    }

    File DestinationFolder
    {
        DestinationPath = "F:\VMs\$ServerName\"
        type            = 'Directory'
        Ensure          = 'Present'
    }

    #
    # The Base Eval image needs to be setup in EUFI format
    # see: https://technet.microsoft.com/en-us/library/hh304353(v=ws.10).aspx
    # or, do as I did. Run an install of 2016 in a VM
    # then overwrite the VM with the Install.WIM
    File CopyBaseImage
    {
        SourcePath = 'F:\VMs\Base\Server2016\2016EvalGui.vhdx'
        DestinationPath = "F:\VMs\$ServerName\$ServerName`.vhdx"
        DependsOn = '[File]DestinationFolder'
    }
    


    #
    # CopyUnattendedXml requires 
    # Use-WindowsUnattend -Path 'H:\' -UnattendPath F:\VMs\Sysprep\Unattend.xml
    # run on the base image
    xVhdFile CopyUnattendedXml
    {
        VhdPath =  "F:\VMs\$ServerName\$ServerName`.vhdx"
        FileDirectory =  MSFT_xFileDirectory {
            SourcePath = 'F:\VMs\Sysprep\2016DataCenterEval_2.xml'
            DestinationPath = "\Windows\System32\Sysprep\Unattend.xml" #'\Windows\System32\Sysprep\Unattend.xml'
                                                        # Unattend.xml 
        }
        DependsOn = '[File]CopyBaseImage'
    
    }


    xVMHyperv "Create$ServerName"
    {
        Name = $ServerName
        VHDPath = "F:\VMs\$ServerName\$ServerName`.vhdx"
        DependsOn = '[xVMSwitch]InternalSwitch','[File]CopyBaseImage','[xVhdFile]CopyUnattendedXml'
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

Lab01