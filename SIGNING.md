# Signing

Handling signing in the [release workflow](https://github.com/CodeReaper/powercast-ios/actions/workflows/release.yml) a number of variables and secrets needs to be set up.

## Variables

### `DEVELOPMENT_TEAM`

This is the team identifier Apple has asigned in the form of `A00AAAAAAA`.

### `ORGANIZATION_IDENTIFIER`

This is the first part of the bundle identifier and is expected to contain part of the reversed-uri naming scheme of bundle identifiers. Example: `com.example`

### `PROVISIONING_PROFILE`

This is the name given to the provisioning profile that has been configured with the bundle identifier for this app and a distribtution certificate. The distribtution certificate is descripted further under secrets.

## Secrets

### App Store Connect Key

A key to handle communication with app store connect is used to download provisioning profiles and to upload the app.

This key is set up in [Developer portal > Users and Access > Keys > App Store Connect API](https://appstoreconnect.apple.com/access/api).

To use this key three seperate secrets needed to be defined:

| Name | Type | Description |
|---|---|---|
| `APPSTORE_ISSUER_ID` | string | This value is global per team |
| `APPSTORE_KEY_ID` | string | This value is unique per application |
| `APPSTORE_KEY_P8` | base64 | This value is a private key pem file downloaded when creating the key |

### Distribution Certificate

A distribution certificate must be created at [Developer portal > Certificates](https://developer.apple.com/account/resources/certificates/list)

Apple provides a guide to make a certificate request which ends with the certificate and its private key being in your keychain.

Find and select both (key and certificate) and export them to a P12 file.

| Name | Type | Description |
|---|---|---|
| `APPSTORE_CERTIFICATE_P12` | base64 | This value is an exported certificate and private key stored in a P12 file |
| `APPSTORE_CERTIFICATE_P12_PASSWORD` | string | The is the password for the P12 file |
