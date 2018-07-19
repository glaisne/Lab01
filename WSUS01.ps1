$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'Localhost'
            PSDscAllowPlainTextPassword = $True
        }
    )
}


Configuration WSUS01
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName @{ModuleName="xNetworking";ModuleVersion="5.3.0.0"}
    Import-DscResource -ModuleName @{ModuleName="xComputerManagement";ModuleVersion="3.1.0.0"}

    LocalConfigurationManager
    {
        RebootNodeIfNeeded = $True
    } 

    WindowsFeature UpdateServices
    {
        Name = 'UpdateServices'
        Ensure = 'Present'
    }

    WindowsFeature UpdateServices-WidDB
    {
        Name = 'UpdateServices-WidDB'
        Ensure = 'Present'
    }

    WindowsFeature UpdateServices-Services
    {
        Name = 'UpdateServices-Services'
        Ensure = 'Present'
    }

    WindowsFeature UpdateServices-RSAT
    {
        Name = 'UpdateServices-RSAT'
        Ensure = 'Present'
    }

    xIpAddress IPAddress
    {
        IPAddress       = "10.10.10.5"
        InterfaceAlias  = "Ethernet 2"
        AddressFamily   = "IPv4"
    }

    xComputer Rename
    {
        Name = "WSUS01"
    }
}

WSUS01 -ConfigurationData $ConfigurationData
