configuration DeleteLab01
{
    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName @{ModuleName="xHyper-V";ModuleVersion="3.12.0.0"}

    $VMRootPath = "C:\VMs"

    Node Localhost
    {

        xVMHyperv "Delete WSUS01"
        {
            Name            = 'WSUS01'
            VHDPath         = "$VMRootPath\WSUS01\WSUS01`.vhdx"
            Ensure          = 'Absent'
            State           = 'Off'
        }
        
        File "DeleteBaseImage WSUS01"
        {
            DestinationPath = "$VMRootPath\WSUS01\WSUS01.vhdx"
            Ensure = 'Absent'
        }
    
        File "DestinationFolder WSUS01"
        {
            DestinationPath = "$VMRootPath\WSUS01\"
            type            = 'Directory'
            Ensure          = 'Absent'
        }

        xVMHyperv "Delete App01"
        {
            Name            = 'App01'
            VHDPath         = "$VMRootPath\App01\App01`.vhdx"
            Ensure          = 'Absent'
            State           = 'Off'
        }
        
        File "DeleteBaseImage App01"
        {
            DestinationPath = "$VMRootPath\App01\App01.vhdx"
            Ensure = 'Absent'
        }
    
        File "DestinationFolder App01"
        {
            DestinationPath = "$VMRootPath\App01\"
            type            = 'Directory'
            Ensure          = 'Absent'
        }

        xVMHyperv "Delete DC02"
        {
            Name            = 'DC02'
            VHDPath         = "$VMRootPath\DC02\DC02`.vhdx"
            Ensure          = 'Absent'
            State           = 'Off'
        }
        
        File "DeleteBaseImage DC02"
        {
            DestinationPath = "$VMRootPath\DC02\DC02.vhdx"
            Ensure = 'Absent'
        }
    
        File "DestinationFolder DC02"
        {
            DestinationPath = "$VMRootPath\DC02\"
            type            = 'Directory'
            Ensure          = 'Absent'
        }

        xVMHyperv "Delete DC01"
        {
            Name            = 'DC01'
            VHDPath         = "$VMRootPath\DC01\DC01`.vhdx"
            Ensure          = 'Absent'
            State           = 'Off'
        }
        
        File "DeleteBaseImage DC01"
        {
            DestinationPath = "$VMRootPath\DC01\DC01.vhdx"
            Ensure = 'Absent'
        }
    
        File "DestinationFolder DC01"
        {
            DestinationPath = "$VMRootPath\DC01\"
            type            = 'Directory'
            Ensure          = 'Absent'
        }
    }
}
DeleteLab01
