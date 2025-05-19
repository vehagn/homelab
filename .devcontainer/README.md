## DevPod Instructions

Changes if necessary:
1. IMAGE_NAME in [build_dev_container.yaml](/.github/workflows/build_dev_container.yaml).
2. Features in [devcontainer.json image builder](/.github/.devcontainer/devcontainer.json).
3. Image in [devcontainer.json](/.devcontainer/devcontainer.json).
4. DevPod link below, to your liking. Note: workspace property below doesn't as of now. [Open Issue](https://github.com/loft-sh/devpod/issues/1843).
5. Create docker/k8s provider in DevPod app. Change settings to your liking.

[![Open in DevPod!](https://devpod.sh/assets/open-in-devpod.svg)](https://devpod.sh/open#git@github.com:karteekiitg/homelab.git@prod&workspace=my-k8s-workspace&provider=docker&ide=zed)

Note: If using branches for prod, staging, dev as intended, change the above link adding **@BRANCH** at the end of your git url (e.g. https://devpod.sh/open#git@github.com:karteekiitg/homelab.git@prod) or alternatively add it in devpod directly (need to do that everytime you create a workspace in ui or cmdline).

Note: Suggest to use original image (i.e no need to change step 1,2 and 3) to reduce complexity, unless you have a specific reason to use a different image. When you do have a valid reason not to,that you think benefits others, raise a Issue/PR.

Note: By default, tries to load `.env` from the project root and `.devcontainer/infisical_secrets.env` to the environment variables in the devcontainer.

## Infisical Setup (Optional)

1.  **Infisical Console**:
    Create an infisical account, setup a project, create folders tofu, tofu_rw, k8s and k8s_rw. In Admin -> Access Control -> Identities, create an identity called Terraform. Click on that identity, click on universal auth, add client secret, then note the client secret and client id. Go back to Secrets -> Your project -> Other -> Access Control -> Machine Identities -> Add Identity, select the identity you just created and select the role as Developer. Also highly recommended to tick Delete Protection in Secrets -> Your project -> Other -> Project Settings. Here, in the same page (Project Settings), you can copy your Project ID from the top right corner. Your infisical domain is either https://eu.infisical.com or https://infisical.com based on what you signed up for on cloud or your own url, if self-hosted. Also note that in some places (like .infisical.json), project id and workspace id are analogous.

2.  **Infisical Setup**:
    Modify [.infisical.json](/.infisical.json) and [.env](/.env) based on the above directions and commit to git (i.e. before devcontainer is created). Then after devcontainer/workspace is created, for the first time, follow the below steps:

3.  **Prepare the Infisical Secrets File**:
    Run the following command in your terminal at the root of the `homelab` project by replacing "<your_infisical_client_secret>" with your actual infisical secret.
    ```shell
    LINE_TO_ADD='TF_VAR_infisical_client_secret="<your_infisical_client_secret>"' # Note: Change this
    SECRETS_FILE=".devcontainer/infisical_secrets.env"

    # Check if the file already contains a line for the secret.
    # We use a general grep for "TF_VAR_infisical_client_secret" to avoid adding duplicates
    # if the user has already manually created/edited the line.
    # The 2>/dev/null suppresses "No such file or directory" from grep if $SECRETS_FILE doesn't exist.
    if ! grep -Fq "TF_VAR_infisical_client_secret" "$SECRETS_FILE" 2>/dev/null; then
      echo "$LINE_TO_ADD" >> "$SECRETS_FILE"
      echo "Added TF_VAR_infisical_client_secret to '$SECRETS_FILE'."
    else
      echo "TF_VAR_infisical_client_secret line already exists in '$SECRETS_FILE'."
    fi
    ```

4.  **Security Note**:
    The file `.devcontainer/infisical_secrets.env` is covered by the `*secrets*.env` pattern in `.gitignore` and will **not** be committed to your repository.

5.  **Activate Changes**:
    Now source your Zsh configuration. This ensures the Infisical setup script (which reads `.devcontainer/infisical_secrets.env`) is executed:
    ```shell
    source ~/.zshrc
    ```

If you want to get all your other Infisical secrets into your devcontainer environment automatically (beyond just the client secret), ensure `homelab/.env` is also set up correctly with your Infisical project details (domain, project ID, path, etc.). The `setup_infisical.sh` script, orchestrated by `customize_zsh.sh` (which modifies `.zshrc`), will then use these details to fetch and export secrets into your shell.

## GCloud Cli Setup (Optional)
Run the below commands to setup gcloud cli in your devpod workspace - after devcontainer/workspace is created, for the first time and when the authentication expires.

1.  **Login and create Application Default Credentials:**
    ```shell
    gcloud auth application-default login --no-launch-browser
    ```
2.  **Set the quota project for your Application Default Credentials:**
    You will likely see a warning after the login command about a missing quota project. Use the following command to set it, replacing `homelab-454718` with your actual Google Cloud Project ID:
    ```shell
    gcloud auth application-default set-quota-project homelab-454718
    ```
    This step is crucial to ensure that API calls made using these credentials are correctly billed and use the appropriate project's quotas.

### Issues
Currently few bugs are reported in DevPod.
1. [Deeplink](https://github.com/loft-sh/devpod/issues/1843) doesn't work as it is supposed to. So workspace name is not auto-filled.

TODO: Look into how PVs and multiple workspaces work.
