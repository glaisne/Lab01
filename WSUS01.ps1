configuration WSUS01
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration


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
}

WSUS01