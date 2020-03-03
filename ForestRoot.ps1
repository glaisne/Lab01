<<<<<<< HEAD
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'Localhost'
            PSDscAllowPlainTextPassword = $True
        }
    )
}


configuration ForestRoot
{
    param (
 
        [Parameter(Mandatory=$true)]
        [PSCredential] $DomainCredentials,

        [Parameter(Mandatory=$true)]
        [string] $DomainName
    )


    Import-DscResource -ModuleName @{ModuleName="PSDesiredStateConfiguration";ModuleVersion="1.1"}
    Import-DscResource -ModuleName @{ModuleName="xActiveDirectory";ModuleVersion="3.0.0.0"}
    Import-DscResource -ModuleName @{ModuleName="xNetworking";ModuleVersion="5.7.0.0"}
    Import-DscResource -ModuleName @{ModuleName="xComputerManagement";ModuleVersion="4.1.0.0"}
    Import-DscResource -ModuleName @{ModuleName="xPendingReboot";ModuleVersion="0.4.0.0"}

    Node $AllNodes.NodeName
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $True
        } 

        xIpAddress IPAddress
        {
            IPAddress       = "10.10.10.10"
            InterfaceAlias  = "Ethernet"
            AddressFamily   = "IPv4"
        }
        
        xDnsServerAddress DnsServerAddress
        {
            Address        = "10.10.10.10"
            InterfaceAlias = "Ethernet"
            AddressFamily  = "IPv4"
            Validate       = $Validate
        }

        xDefaultGatewayAddress SetDefaultGateway
        {
            Address        = "10.10.10.1"
            InterfaceAlias = "Ethernet"
            AddressFamily  = "IPv4"
        }

        xNetAdapterBinding DisableIPv6
        {
            InterfaceAlias = 'Ethernet'
            ComponentId = 'ms_tcpip6'
            State = 'Disabled'
        }

        xComputer Rename
        {
            Name = "DC01"
        }


        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            #DependsOn = '[xComputer]Rename'
        }

        xADDomain FirstDS
        {
            DomainName = $domainName
            DomainAdministratorCredential = $DomainCredentials
            SafemodeAdministratorPassword = $DomainCredentials
            # DnsDelegationCredential = $DomainCredentials
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xADDomainController Promote
        {
            DomainName = $domainName
            DomainAdministratorCredential = $DomainCredentials
            SafemodeAdministratorPassword = $DomainCredentials
            #DnsDelegationCredential = $DNSDelegationCred
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xPendingReboot Reboot1
        { 
            Name = 'After_FirstDS'
        }

        WindowsFeature ADDS
        {
            Name = 'RSAT-ADDS'
            Ensure = 'Present'
            IncludeAllSubFeature = $True
        }

        WindowsFeature ADLDS
        {
            Name = 'ADLDS'
            Ensure = 'Present'
        }
    
        xWaitForADDomain DscForestWait
        {
            DomainName = $domainName
            DomainUserCredential = $DomainCredentials
            #RetryCount = 20
            #RetryIntervalSec = 60
            RebootRetryCount = 5
            DependsOn = "[xADDomain]FirstDS"
        }
    
        xADUser FirstUser
        {
            DomainName = $domainName
            DomainAdministratorCredential = $DomainCredentials
            UserName = "dummy"
            #Password = $DomainCredentials
            Ensure = "Present"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }
    }
}

ForestRoot -ConfigurationData $ConfigurationData -DomainCredentials $([pscredential]::new('Administrator', $(ConvertTo-SecureString -String 'Pa55w0rd!101' -AsPlainText -Force))) -
=======
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'Localhost'
            PSDscAllowPlainTextPassword = $True
        }
    )
}


configuration ForestRoot
{
    param (
 
        [Parameter(Mandatory=$true)]
        [PSCredential] $DomainCredentials
    )


    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName @{ModuleName="xActiveDirectory";ModuleVersion="2.21.0.0"}
    Import-DscResource -ModuleName @{ModuleName="xNetworking";ModuleVersion="5.7.0.0"}
    Import-DscResource -ModuleName @{ModuleName="xComputerManagement";ModuleVersion="4.1.0.0"}
    Import-DscResource -ModuleName @{ModuleName="xPendingReboot";ModuleVersion="0.4.0.0"}

    $domainName        = 'one.com'

    Node $AllNodes.NodeName
    {

        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $True
            AllowModuleOverwrite = $true
        } 

        xIpAddress IPAddress
        {
            IPAddress       = "10.10.10.10"
            InterfaceAlias  = "Ethernet"
            AddressFamily   = "IPv4"
        }
        
        xDnsServerAddress DnsServerAddress
        {
            Address        = "10.10.10.10"
            InterfaceAlias = "Ethernet"
            AddressFamily  = "IPv4"
            Validate       = $Validate
        }

        xDefaultGatewayAddress SetDefaultGateway
        {
            Address        = "10.10.10.1"
            InterfaceAlias = "Ethernet"
            AddressFamily  = "IPv4"
        }

        xNetAdapterBinding DisableIPv6
        {
            InterfaceAlias = 'Ethernet'
            ComponentId = 'ms_tcpip6'
            State = 'Disabled'
        }

        xComputer Rename
        {
            Name = "DC01"
        }


        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            #DependsOn = '[xComputer]Rename'
        }

        xADDomain FirstDS
        {
            DomainName = $domainName
            DomainAdministratorCredential = $DomainCredentials
            SafemodeAdministratorPassword = $DomainCredentials
            # DnsDelegationCredential = $DomainCredentials
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xADDomainController Promote
        {
            DomainName = $domainName
            DomainAdministratorCredential = $DomainCredentials
            SafemodeAdministratorPassword = $DomainCredentials
            #DnsDelegationCredential = $DNSDelegationCred
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xPendingReboot Reboot1
        { 
            Name = 'After_FirstDS'
        }

        WindowsFeature ADDS
        {
            Name = 'RSAT-ADDS'
            Ensure = 'Present'
            IncludeAllSubFeature = $True
        }

        WindowsFeature ADLDS
        {
            Name = 'ADLDS'
            Ensure = 'Present'
        }
    
        xWaitForADDomain DscForestWait
        {
            DomainName = $domainName
            DomainUserCredential = $DomainCredentials
            #RetryCount = 20
            #RetryIntervalSec = 60
            RebootRetryCount = 5
            DependsOn = "[xADDomain]FirstDS"
        }
    
        xADUser FirstUser
        {
            DomainName = $domainName
            DomainAdministratorCredential = $DomainCredentials
            UserName = "dummy"
            #Password = $DomainCredentials
            Ensure = "Present"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }
    }
}

ForestRoot -ConfigurationData $ConfigurationData -DomainCredentials $([pscredential]::new('Administrator', $(ConvertTo-SecureString -String 'Password!101' -AsPlainText -Force)))
>>>>>>> 6d7bfbe223d854e719d4908876925de7d9cd8496
