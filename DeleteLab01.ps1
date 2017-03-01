configuration DeleteLab01
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    import-DscResource -ModuleName xHyper-V


    Node Localhost
    {

        xVMHyperv "Delete WSUS01"
        {
            Name            = 'WSUS01'
            VHDPath         = "F:\VMs\WSUS01\WSUS01`.vhdx"
            Ensure          = 'Absent'
            State           = 'Off'
        }
        
        File "DeleteBaseImage WSUS01"
        {
            DestinationPath = "F:\VMs\WSUS01\WSUS01.vhdx"
            Ensure = 'Absent'
        }
    
        File "DestinationFolder WSUS01"
        {
            DestinationPath = "F:\VMs\WSUS01\"
            type            = 'Directory'
            Ensure          = 'Absent'
        }

        xVMHyperv "Delete App01"
        {
            Name            = 'App01'
            VHDPath         = "F:\VMs\App01\App01`.vhdx"
            Ensure          = 'Absent'
            State           = 'Off'
        }
        
        File "DeleteBaseImage App01"
        {
            DestinationPath = "F:\VMs\App01\App01.vhdx"
            Ensure = 'Absent'
        }
    
        File "DestinationFolder App01"
        {
            DestinationPath = "F:\VMs\App01\"
            type            = 'Directory'
            Ensure          = 'Absent'
        }

        xVMHyperv "Delete DC02"
        {
            Name            = 'DC02'
            VHDPath         = "F:\VMs\DC02\DC02`.vhdx"
            Ensure          = 'Absent'
            State           = 'Off'
        }
        
        File "DeleteBaseImage DC02"
        {
            DestinationPath = "F:\VMs\DC02\DC02.vhdx"
            Ensure = 'Absent'
        }
    
        File "DestinationFolder DC02"
        {
            DestinationPath = "F:\VMs\DC02\"
            type            = 'Directory'
            Ensure          = 'Absent'
        }

        xVMHyperv "Delete DC01"
        {
            Name            = 'DC01'
            VHDPath         = "F:\VMs\DC01\DC01`.vhdx"
            Ensure          = 'Absent'
            State           = 'Off'
        }
        
        File "DeleteBaseImage DC01"
        {
            DestinationPath = "F:\VMs\DC01\DC01.vhdx"
            Ensure = 'Absent'
        }
    
        File "DestinationFolder DC01"
        {
            DestinationPath = "F:\VMs\DC01\"
            type            = 'Directory'
            Ensure          = 'Absent'
        }
    }
}
DeleteLab01