[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # Make sure there are not other modules imported that will conflict with mocks.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

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

    $mockJoinPath = {
        return "Cert:\LocalMachine\$ChildPath"
    }

    $mockTestPath = {
        return $true
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Find-Certificate' -Tag 'FindCertificate' {
    BeforeAll {
        Mock -CommandName Join-Path     -MockWith $mockJoinPath
        Mock -CommandName Get-ChildItem -MockWith $mockGetChildItem
        Mock -CommandName Test-Path     -MockWith $mockTestPath

        #Generate test cert object to run against.
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
        $certificateEKUReverse = @('Client authentication','Server Authentication')
        $certificateEKUNoMatch = $certificateEKU + @('Encrypting File System')
        $certificateSubject = 'CN=contoso, DC=com'
        $certificateFriendlyName = 'Contoso Test Cert'

        $validThumbprint = 'B994DA47197931EFA3B00CB2DF34E2510E404C8D'
        $expiredThumbprint = '31343B742B3062CF880487C2125E851E2884D00A'
        $noCertificateThumbprint = '1111111111111111111111111111111111111111'

        $validCertificate = @{
            FriendlyName = $certificateFriendlyName
            Subject = $certificateSubject
            Thumbprint = $validThumbprint
            NotBefore = ((Get-Date) - (New-TimeSpan -Days 1))
            NotAfter = ((Get-Date) + (New-TimeSpan -Days 30))
            Issuer = $certificateSubject
            DnsNameList = $certificateDNSNames | ForEach-Object { @{ Unicode = $PSItem } }
            Extensions = @{ KeyUsages = $certificateKeyUsage -join ", " }
            EnhancedKeyUsageList = $certificateEKU | ForEach-Object { @{ FriendlyName = $PSItem } }
        }

        $expiredCertificate = @{
            FriendlyName = $certificateFriendlyName
            Subject = $certificateSubject
            Thumbprint = $expiredThumbprint
            NotBefore = ((Get-Date) - (New-TimeSpan -Days 2))
            NotAfter = ((Get-Date) - (New-TimeSpan -Days 1))
            Issuer = $certificateSubject
            DnsNameList = $certificateDNSNames | ForEach-Object { @{ Unicode = $PSItem } }
            Extensions = @{ KeyUsages = $certificateKeyUsage -join ", " }
            EnhancedKeyUsageList = $certificateEKU | ForEach-Object { @{ FriendlyName = $PSItem } }
        }
    }

    Context 'Thumbprint only is passed and matching certificate exists' {
        It 'Should not throw exception' {
            { $script:result = Find-Certificate -Thumbprint $validThumbprint } | Should -Not -Throw
        }

        It 'Should return expected certificate' {
            $script:result.Thumbprint | Should -Be $validThumbprint
        }

        It 'Should call expected mocks' {
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
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
            Should -Invoke Test-Path -Exactly -Times 1 -Scope "context"
            Should -Invoke Get-ChildItem -Exactly -Times 1 -Scope "context"
            # Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope "context"
            # Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope "context"
        }
    }
}
