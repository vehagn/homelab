## GCS Remote

1. Create a [Service Account](https://cloud.google.com/iam/docs/service-accounts-create) named tofu (after enabling the
   IAM API if needed). Leave the permissions blank.
2. Create and download the [service account key](https://cloud.google.com/iam/docs/keys-create-delete#creating).
3. Create a GCS bucket for tofu state with public access prevention and versioning as necessary.
4. In the permissions tab of the bucket, give **Storage Object Admin** access to the service account.
5. Copy backend.tf.sample to backend.tf and make necessary changes.

```shell
cp remote_backend.tf.sample remote_backend.tf
```

### Encryption key

Generate the encryption key

```shell
python3 -c 'import os;import base64;print(base64.b64encode(os.urandom(32)).decode("utf-8"))'
```

`Without the encryption key, your state would not be recoverable. Store in a password manager, if not using any kms like bws.`

1. Set the enable_state in remote_state.auto.tfvars
1. Set the enable_state in remote_state.auto.tfvars or bws.auto.tfvars. (Note: If not using bws, don't commit this file, rename it tosomething like remote_state_secrets.auto.tfvars).

```shell
tofu init -migrate-state
```

### Beta Notice

`Please treat this as beta and only use for air-gapped installations as of now. Will remove the beta tag after testing it in due course.`
