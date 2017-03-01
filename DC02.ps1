$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'Localhost'
            PSDscAllowPlainTextPassword = $True
        }
    )
}


configuration DC02
{
    param (
 
        [Parameter(Mandatory=$true)]
        [PSCredential] $DomainCredentials
    )


    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xPendingReboot
    Import-DscResource -ModuleName xComputerManagement

    $domainName        = 'one.com'

    Node $AllNodes.NodeName
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $True
        } 

        xIpAddress IPAddress
        {
            IPAddress       = "10.10.10.11"
            InterfaceAlias  = "Ethernet"
            PrefixLength    = 24
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
            Name = "DC02"
        }
   
        xWaitForADDomain DscForestWait
        {
            DomainName = $domainName
            #DomainUserCredential = $DomainCredentials
            RetryCount = 20
            RetryIntervalSec = (5 * 60)
            # RebootRetryCount = 5
            # DependsOn = "[xIpAddress]IPAddress", "[xDnsServerAddress]DnsServerAddress", "[xDefaultGatewayAddress]SetDefaultGateway"
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            #DependsOn = '[xComputer]Rename'
        }

        WindowsFeature ADLDS
        {
            Name = 'ADLDS'
            Ensure = 'Present'
        }

        xADDomainController Promote
        {
            DomainName = $domainName
            DomainAdministratorCredential = $DomainCredentials
            SafemodeAdministratorPassword = $DomainCredentials
            #DnsDelegationCredential = $DNSDelegationCred
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        WindowsFeature ADDS
        {
            Name = 'RSAT-ADDS'
            Ensure = 'Present'
            IncludeAllSubFeature = $True
        }
    }
}

DC02 -ConfigurationData $ConfigurationData -DomainCredentials $([pscredential]::new('Administrator', $(ConvertTo-SecureString -String 'Pa55w0rd!101' -AsPlainText -Force)))