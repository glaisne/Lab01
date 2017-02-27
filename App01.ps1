﻿$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'Localhost'
            PSDscAllowPlainTextPassword = $True
        }
    )
}


configuration App01
{
    param (
 
        [Parameter(Mandatory=$true)]
        [PSCredential] $DomainCredentials
    )


    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xPendingReboot

    $domainName        = 'one.com'

    Node $AllNodes.NodeName
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $True
        } 

        xIpAddress IPAddress
        {
            IPAddress       = "10.10.10.21"
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
   
        xWaitForADDomain DscForestWait
        {
            DomainName = $domainName
            DomainUserCredential = $DomainCredentials
            RetryCount = 20
            RetryIntervalSec = 60
            RebootRetryCount = 5
            DependsOn = "[xIpAddress]IPAddress", "[xDnsServerAddress]DnsServerAddress", "[xDefaultGatewayAddress]SetDefaultGateway"
        }

        xComputer JoinDomain
        {
            Name       = "App01"
            DomainName = $domainName

        }

    }
}

App01 -ConfigurationData $ConfigurationData -Credentail $([pscredential]::new('Administrator', $(ConvertTo-SecureString -String 'Pa55w0rd!101' -AsPlainText -Force))) -Domain $DomainName