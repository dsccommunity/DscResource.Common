<#
    .SYNOPSIS
        Locates one or more certificates using the passed certificate selector parameters.

    .DESCRIPTION
        A common function to find certificates based on multiple search filters, including,
        but not limited to: Thumbprint, Friendly Name, DNS Names, Key Usage, Issuers, etc.

        Locates one or more certificates using the passed certificate selector parameters.
        If more than one certificate is found matching the selector criteria, they will be
        returned in order of descending expiration date.

    .PARAMETER Thumbprint
        The thumbprint of the certificate to find.

    .PARAMETER FriendlyName
        The friendly name of the certificate to find.

    .PARAMETER Subject
        The subject of the certificate to find.

    .PARAMETER DNSName
        The subject alternative name of the certificate to export must contain these values.

    .PARAMETER Issuer
        The issuer of the certificate to find.

    .PARAMETER KeyUsage
        The key usage of the certificate to find must contain these values.

    .PARAMETER EnhancedKeyUsage
        The enhanced key usage of the certificate to find must contain these values.

    .PARAMETER Store
        The Windows Certificate Store Name to search for the certificate in.
        Defaults to 'My'.

    .PARAMETER AllowExpired
        Allows expired certificates to be returned.

    .OUTPUTS
        System.Security.Cryptography.X509Certificates.X509Certificate2

    .EXAMPLE
        Find-Certificate -Thumbprint '1111111111111111111111111111111111111111'

        Return certificate that matches thumbprint.

    .EXAMPLE
        Find-Certificate -KeyUsage 'DataEncipherment', 'DigitalSignature'

        Return certificate(s) that have specific key usage.

    .EXAMPLE
        Find-Certificate -DNSName 'www.fabrikam.com', 'www.contoso.com'

        Return certificate(s) filtered on specific DNS Names.

    .EXAMPLE
        Find-Certificate -Subject 'CN=contoso, DC=com'

        Return certificate(s) with specific subject.

    .EXAMPLE
        Find-Certificate -Issuer 'CN=contoso-ca, DC=com' -AllowExpired $true

        Return all certificates from specific issuer, including expired certificates.

    .EXAMPLE
        Find-Certificate -EnhancedKeyUsage @('Client authentication','Server Authentication') -AllowExpired $true

        Return all certificates that can be used for server or client authentication,
        including expired certificates.

    .EXAMPLE
        Find-Certificate -FriendlyName 'My IIS Site SSL Cert'

        Return certificate based on FriendlyName.
#>
function Find-Certificate
{
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param
    (
        [Parameter()]
        [System.String]
        $Thumbprint,

        [Parameter()]
        [System.String]
        $FriendlyName,

        [Parameter()]
        [System.String]
        $Subject,

        [Parameter()]
        [System.String[]]
        $DNSName,

        [Parameter()]
        [System.String]
        $Issuer,

        [Parameter()]
        [System.String[]]
        $KeyUsage,

        [Parameter()]
        [System.String[]]
        $EnhancedKeyUsage,

        [Parameter()]
        [System.String]
        $Store = 'My',

        [Parameter()]
        [Boolean]
        $AllowExpired = $false
    )

    $certPath = Join-Path -Path 'Cert:\LocalMachine' -ChildPath $Store

    if (-not (Test-Path -Path $certPath))
    {
        # The Certificte Path is not valid
        New-ArgumentException `
            -Message ($script:localizedData.CertificatePathError -f $certPath) `
            -ArgumentName 'Store'
    } # if

    # Assemble the filter to use to select the certificate
    $certFilters = @()

    if ($PSBoundParameters.ContainsKey('Thumbprint'))
    {
        $certFilters += @('($_.Thumbprint -eq $Thumbprint)')
    } # if

    if ($PSBoundParameters.ContainsKey('FriendlyName'))
    {
        $certFilters += @('($_.FriendlyName -eq $FriendlyName)')
    } # if

    if ($PSBoundParameters.ContainsKey('Subject'))
    {
        $certFilters += @('($_.Subject -eq $Subject)')
    } # if

    if ($PSBoundParameters.ContainsKey('Issuer'))
    {
        $certFilters += @('($_.Issuer -eq $Issuer)')
    } # if

    if (-not $AllowExpired)
    {
        $certFilters += @('(((Get-Date) -le $_.NotAfter) -and ((Get-Date) -ge $_.NotBefore))')
    } # if

    if ($PSBoundParameters.ContainsKey('DNSName'))
    {
        $certFilters += @('(@(Compare-Object -ReferenceObject $_.DNSNameList.Unicode -DifferenceObject $DNSName | Where-Object -Property SideIndicator -eq "=>").Count -eq 0)')
    } # if

    if ($PSBoundParameters.ContainsKey('KeyUsage'))
    {
        $certFilters += @('(@(Compare-Object -ReferenceObject ($_.Extensions.KeyUsages -split ", ") -DifferenceObject $KeyUsage | Where-Object -Property SideIndicator -eq "=>").Count -eq 0)')
    } # if

    if ($PSBoundParameters.ContainsKey('EnhancedKeyUsage'))
    {
        $certFilters += @('(@(Compare-Object -ReferenceObject ($_.EnhancedKeyUsageList.FriendlyName) -DifferenceObject $EnhancedKeyUsage | Where-Object -Property SideIndicator -eq "=>").Count -eq 0)')
    } # if

    # Join all the filters together
    $certFilterScript = '(' + ($certFilters -join ' -and ') + ')'

    Write-Verbose `
        -Message ($script:localizedData.SearchingForCertificateUsingFilters -f $store, $certFilterScript) `
        -Verbose

    $certs = Get-ChildItem -Path $certPath |
        Where-Object -FilterScript ([ScriptBlock]::Create($certFilterScript))

    # Sort the certificates
    if ($certs.count -gt 1)
    {
        $certs = $certs | Sort-Object -Descending -Property 'NotAfter'
    } # if

    return $certs
} # end function Find-Certificate
