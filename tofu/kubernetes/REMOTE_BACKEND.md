## GCS Remote
1. Create a [Service Account](https://cloud.google.com/iam/docs/service-accounts-create) named tofu (after enabling the IAM API if needed). Leave the permissions blank.
1. Create and download the [service account key](https://cloud.google.com/iam/docs/keys-create-delete#creating).
1. Create a GCS bucket for tofu state with public access prevention and versioning as necessary.
1. In the permissions tab of the bucket, give **Storage Object Admin** access to the service account.
1. Copy backend.tf.sample to backend.tf and make necessary changes.
```shell
cp remote_backend.tf.sample remote_backend.tf
```

### Encryption key

Generate the encryption key

```shell
python3 -c 'import os;import base64;print(base64.b64encode(os.urandom(32)).decode("utf-8"))'
```

![#f03c15](https://placehold.co/15x15/f03c15/f03c15.png) `Without the encryption key, your state would not be recoverable. Store in a password manager, if not using any kms like bws.`

### Environment variables

```shell
export GOOGLE_APPLICATION_CREDENTIALS="<YOUR_DOWNLOADED_KEY_PATH>"
export GOOGLE_ENCRYPTION_KEY="<YOUR_GENERATED_ENCRYPTION_KEY>"
```

Run tofu init / plan / apply as usual.

### Bitwarden Secrets Manager

Store the downloaded key contents and generated encryption key into GOOGLE_CREDENTIALS and GOOGLE_ENCRYPTION_KEY respectively in bws.

Run bws run -- tofu init / plan / apply as usual.

### Beta Notice

![#f03c15](https://placehold.co/15x15/f03c15/f03c15.png) `Please treat this as beta and only use for air-gapped installations as of now. Will remove the beta tag after testing it in due course.`
