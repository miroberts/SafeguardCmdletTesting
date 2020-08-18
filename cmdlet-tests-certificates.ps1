try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Certificates Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
# TODO - stubbed code
# Clear-SafeguardSslCertificateForAppliance
# Install-SafeguardAuditLogSigningCertificate
# Install-SafeguardSessionCertificate
# Install-SafeguardSslCertificate
# Install-SafeguardTrustedCertificate
# Reset-SafeguardSessionCertificate
# Set-SafeguardSslCertificateForAppliance
# Uninstall-SafeguardAuditLogSigningCertificate
# Uninstall-SafeguardSslCertificate
# Uninstall-SafeguardTrustedCertificate
# Update-SafeguardAccessCertificationGroupFromAD

# ===== Covered Commands =====
# Get-SafeguardAccessCertificationAccount
# Get-ADAccessCertificationIdentity
# Get-SafeguardAccessCertificationAll
# Get-SafeguardAccessCertificationGroup
# Get-SafeguardAccessCertificationIdentity
# Get-SafeguardAccessCertificationEntitlement
# New-SafeguardCsr (alias for New-SafeguardCertificateSigningRequest)
# Remove-SafeguardCsr (alias for Get-SafeguardCertificateSigningRequest)
# Get-SafeguardCsr (alias for Remove-SafeguardCertificateSigningRequest)
#

try {
   Get-SafeguardAccessCertificationAccount -Identifier $DATA.appliance -StdOut
   goodResult "Get-SafeguardAccessCertificationAccount" "Successfully called"

   # NOTE
   # these require that ActiveDirectory modules be installed. See "Install Instructions" here
   # https://www.microsoft.com/en-us/download/details.aspx?id=45520
   #
   # Install these
   #   RSAT: Server Manager
   #   RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
   try {
      Get-SafeguardAccessCertificationAll -Identifier $DATA.appliance -OutputDirectory $DATA.outputPaths.certificates -DomainName $DATA.domainName -Credential $DATA.domainCredential
      goodResult "Get-SafeguardAccessCertificationAll" "Successfully called. Check CSV files for output."

      Get-ADAccessCertificationIdentity -StdOut -DomainName $DATA.domainName -Credential $DATA.domainCredential
      goodResult "Get-ADAccessCertificationIdentity" "Successfully called"
   } catch {
      badResult "Access Certification" "Error accessing domain $($DATA.domainName) for Access Certification Info" $_
   }

   Get-SafeguardAccessCertificationGroup -Identifier $DATA.appliance -StdOut
   goodResult "Get-SafeguardAccessCertificationGroup" "Successfully called"

   Get-SafeguardAccessCertificationIdentity -Identifier $DATA.appliance -StdOut
   goodResult "Get-SafeguardAccessCertificationIdentity" "Successfully called"

   # This assumes some entitlement stuff being around for meaningful output?
   Get-SafeguardAccessCertificationEntitlement -Identifier $DATA.appliance -StdOut
   goodResult "Get-SafeguardAccessCertificationEntitlement" "Successfully called"

   try {
      $csr = New-SafeguardCsr -CertificateType Ssl -Subject $DATA.newCsrSubject `
          -DnsNames $DATA.newCsrDns -IpAddresses $DATA.newCsrIpAddress `
          -OutFile "$($DATA.outputPaths.certificates)$($DATA.newCsrOutputFile)"
      goodResult "New-SafeguardCsr" "Successfully created new CSR, thumbprint=$($csr.Thumbprint). Check CSR file for output."
   } catch {
      badResult "New-SafeguardCsr" "Unable to create new CSR for $($DATA.newCsrSubject)" $_
   }

   if ($csr) {
      $retrievedCsr = Get-SafeguardCsr -Thumbprint $csr.Thumbprint
      goodResult "Get-SafeguardCsr" "Successfully retrieved CSR, thumbprint=$($retrievedCsr.Thumbprint)"

      Remove-SafeguardCsr -Thumbprint $retrievedCsr.Thumbprint > $null
      goodResult "Remove-SafeguardCsr" "Successfully removed CSR, thumbprint=$($retrievedCsr.Thumbprint)"

      $csr = $null
   }

} catch {
   badResult "Certificates general" "Unexpected error in Certificates test" $_
} finally {
   try { if ($csr) { Remove-SafeguardCsr -Thumbprint $csr.Thumbprint > $null } } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo
