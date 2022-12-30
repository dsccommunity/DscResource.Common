<#
    .SYNOPSIS
        Returns whether the specified account require a password to be provided.

    .DESCRIPTION
        Returns whether the specified account require a password to be provided.
        If the account is a (global) managed service account, virtual account, or a
        built-in account then there is no need to provide a password.

    .PARAMETER Name
        Credential name for the account.

    .EXAMPLE
        Test-AccountRequirePassword -Name 'DOMAIN\MyMSA$'

        Returns $false as a manged service account does not need a password.

    .EXAMPLE
        Test-AccountRequirePassword -Name 'DOMAIN\MySqlUser'

        Returns $true as a user account need a password.

    .EXAMPLE
        Test-AccountRequirePassword -Name 'NT SERVICE\MSSQL$PAYROLL'

        Returns $false as a virtual account does not need a password.

    .OUTPUTS
        [System.Boolean]
#>
function Test-AccountRequirePassword
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    # Assume local or domain service account.
    $requirePassword = $true

    switch -Regex ($Name.ToUpper())
    {
        # Built-in account.
        '^(?:NT ?AUTHORITY\\)?(SYSTEM|LOCALSERVICE|LOCAL SERVICE|NETWORKSERVICE|NETWORK SERVICE)$' # CSpell: disable-line
        {
            $requirePassword = $false

            break
        }

        # Virtual account.
        '^(?:NT SERVICE\\)(.*)$'
        {
            $requirePassword = $false

            break
        }

        # (Global) Managed Service Account.
        '\$$'
        {
            $requirePassword = $false

            break
        }
    }

    return $requirePassword
}
