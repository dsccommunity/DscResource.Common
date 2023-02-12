BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    # Generate the Valid certificate for testing but remove it from the store straight away
    $certificateDNSNames = @('www.fabrikam.com', 'www.contoso.com')
    $certificateDNSNamesReverse = @('www.contoso.com', 'www.fabrikam.com')
    $certificateDNSNamesNoMatch = $certificateDNSNames + @('www.nothere.com')
    $certificateKeyUsage = @('DigitalSignature', 'DataEncipherment')
    $certificateKeyUsageReverse = @('DataEncipherment', 'DigitalSignature')
    $certificateKeyUsageNoMatch = $certificateKeyUsage + @('KeyEncipherment')
    <#
        To set Enhanced Key Usage, we must use OIDs:
        Enhanced Key Usage. 2.5.29.37
        Client Authentication. 1.3.6.1.5.5.7.3.2
        Server Authentication. 1.3.6.1.5.5.7.3.1
        Microsoft EFS File Recovery. 1.3.6.1.4.1.311.10.3.4.1
    #>
    $certificateEKU = @('Server Authentication', 'Client authentication')
    $certificateEKUOID = '2.5.29.37={text}1.3.6.1.5.5.7.3.2,1.3.6.1.5.5.7.3.1'
    $certificateEKUReverse = @('Client authentication','Server Authentication')
    $certificateEKUNoMatch = $certificateEKU + @('Encrypting File System')
    $certificateSubject = 'CN=contoso, DC=com'
    $certificateFriendlyName = 'Contoso Test Cert'
    $validCertificate = New-SelfSignedCertificate `
        -Subject $certificateSubject `
        -KeyUsage $certificateKeyUsage `
        -KeySpec 'KeyExchange' `
        -TextExtension $certificateEKUOID `
        -DnsName $certificateDNSNames `
        -FriendlyName $certificateFriendlyName `
        -CertStoreLocation 'cert:\CurrentUser' `
        -KeyExportPolicy Exportable
    # Pull the generated certificate from the store so we have the friendlyname
    $validThumbprint = $validCertificate.Thumbprint
    $validCertificate = Get-Item -Path "cert:\CurrentUser\My\$validThumbprint"
    Remove-Item -Path $validCertificate.PSPath -Force

    # Generate the Expired certificate for testing but remove it from the store straight away
    $expiredCertificate = New-SelfSignedCertificate `
        -Subject $certificateSubject `
        -KeyUsage $certificateKeyUsage `
        -KeySpec 'KeyExchange' `
        -TextExtension $certificateEKUOID `
        -DnsName $certificateDNSNames `
        -FriendlyName $certificateFriendlyName `
        -NotBefore ((Get-Date) - (New-TimeSpan -Days 2)) `
        -NotAfter ((Get-Date) - (New-TimeSpan -Days 1)) `
        -CertStoreLocation 'cert:\CurrentUser' `
        -KeyExportPolicy Exportable
    # Pull the generated certificate from the store so we have the friendlyname
    $expiredThumbprint = $expiredCertificate.Thumbprint
    $expiredCertificate = Get-Item -Path "cert:\CurrentUser\My\$expiredThumbprint"
    Remove-Item -Path $expiredCertificate.PSPath -Force

    $noCertificateThumbprint = '1111111111111111111111111111111111111111'

    # Dynamic mock content for Get-ChildItem
    $mockGetChildItem = {
        switch ( $Path )
        {
            'cert:\LocalMachine\My'
            {
                return @( $validCertificate )
            }

            'cert:\LocalMachine\NoCert'
            {
                return @()
            }

            'cert:\LocalMachine\TwoCerts'
            {
                return @( $expiredCertificate, $validCertificate )
            }

            'cert:\LocalMachine\Expired'
            {
                return @( $expiredCertificate )
            }

            default
            {
                throw 'mock called with unexpected value {0}' -f $Path
            }
        }
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Find-Certificate' -Tag 'FindCertificate' {
    BeforeEach {
        Mock `
            -CommandName Test-Path `
            -MockWith { $true }

        Mock `
            -CommandName Get-ChildItem `
            -MockWith $mockGetChildItem
    }

    Context 'Thumbprint only is passed and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -Thumbprint $validThumbprint } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'Thumbprint only is passed and matching certificate does not exist' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -Thumbprint $noCertificateThumbprint } | Should -Not -Throw
        }

        It 'Should return null' {
            $script:result | Should -BeNullOrEmpty
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'FriendlyName only is passed and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -FriendlyName $certificateFriendlyName } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'FriendlyName only is passed and matching certificate does not exist' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -FriendlyName 'Does Not Exist' } | Should -Not -Throw
        }

        It 'Should return null' {
            $script:result | Should -BeNullOrEmpty
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'Subject only is passed and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -Subject $certificateSubject } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'Subject only is passed and matching certificate does not exist' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -Subject 'CN=Does Not Exist' } | Should -Not -Throw
        }

        It 'Should return null' {
            $script:result | Should -BeNullOrEmpty
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'Issuer only is passed and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -Issuer $certificateSubject } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'Issuer only is passed and matching certificate does not exist' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -Issuer 'CN=Does Not Exist' } | Should -Not -Throw
        }

        It 'Should return null' {
            $script:result | Should -BeNullOrEmpty
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'DNSName only is passed and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -DnsName $certificateDNSNames } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'DNSName only is passed in reversed order and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -DnsName $certificateDNSNamesReverse } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'DNSName only is passed with only one matching DNS name and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -DnsName $certificateDNSNames[0] } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'DNSName only is passed but an entry is missing and matching certificate does not exist' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -DnsName $certificateDNSNamesNoMatch } | Should -Not -Throw
        }

        It 'Should return null' {
            $script:result | Should -BeNullOrEmpty
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'KeyUsage only is passed and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -KeyUsage $certificateKeyUsage } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'KeyUsage only is passed in reversed order and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -KeyUsage $certificateKeyUsageReverse } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'KeyUsage only is passed with only one matching DNS name and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -KeyUsage $certificateKeyUsage[0] } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'KeyUsage only is passed but an entry is missing and matching certificate does not exist' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -KeyUsage $certificateKeyUsageNoMatch } | Should -Not -Throw
        }

        It 'Should return null' {
            $script:result | Should -BeNullOrEmpty
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'EnhancedKeyUsage only is passed and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -EnhancedKeyUsage $certificateEKU } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'EnhancedKeyUsage only is passed in reversed order and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -EnhancedKeyUsage $certificateEKUReverse } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'EnhancedKeyUsage only is passed with only one matching DNS name and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -EnhancedKeyUsage $certificateEKU[0] } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'EnhancedKeyUsage only is passed but an entry is missing and matching certificate does not exist' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -EnhancedKeyUsage $certificateEKUNoMatch } | Should -Not -Throw
        }

        It 'Should return null' {
            $script:result | Should -BeNullOrEmpty
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'Thumbprint only is passed and matching certificate does not exist in the store' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -Thumbprint $validThumbprint -Store 'NoCert' } | Should -Not -Throw
        }

        It 'Should return null' {
            $script:result | Should -BeNullOrEmpty
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'FriendlyName only is passed and both valid and expired certificates exist' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -FriendlyName $certificateFriendlyName -Store 'TwoCerts' } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'FriendlyName only is passed and only expired certificates exist' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -FriendlyName $certificateFriendlyName -Store 'Expired' } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result | Should -BeNullOrEmpty
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }

    Context 'FriendlyName only is passed and only expired certificates exist but allowexpired passed' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -FriendlyName $certificateFriendlyName -Store 'Expired' -AllowExpired:$true } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $expiredThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
        }
    }
}
