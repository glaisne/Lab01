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
    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName @{ModuleName="xNetworking";ModuleVersion="5.7.0.0"}
    Import-DscResource -ModuleName @{ModuleName="xComputerManagement";ModuleVersion="4.1.0.0"}

    LocalConfigurationManager
    {
        ActionAfterReboot = 'ContinueConfiguration'
        ConfigurationMode = 'ApplyOnly'
        RebootNodeIfNeeded = $True
        AllowModuleOverwrite = $true
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
