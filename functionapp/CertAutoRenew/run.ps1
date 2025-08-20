param($Request, $TriggerMetadata)

$vaultName = $Request.Body.vaultName
$certName = $Request.Body.certName

Renew-AzKeyVaultCertificate -VaultName $vaultName -Name $certName
@{ result = "Renewed $certName successfully" }