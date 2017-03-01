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
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -moduleName xComputerManagement

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
        PrefixLength    = 24
        AddressFamily   = "IPv4"
    }

    xComputer Rename
    {
        Name = "WSUS01"
    }
}

WSUS01 -ConfigurationData $ConfigurationData