[Flags()]
enum PendingRestartCheck
{
    ComponentBasedServicing = 1
    WindowsUpdate = 2
    PendingFileRename = 4
    PendingComputerRename = 8
    PendingDomainJoin = 16
    ConfigurationManagerClient = 32
    All = 63 # Sum of all values above
}
