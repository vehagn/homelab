#!/bin/bash

if [[ -v TF_VAR_infisical_domain ]] && [[ -n "$TF_VAR_infisical_domain" ]] &&
   [[ -v TF_VAR_infisical_client_id ]] && [[ -n "$TF_VAR_infisical_client_id" ]] &&
   [[ -v TF_VAR_infisical_project_id ]] && [[ -n "$TF_VAR_infisical_project_id" ]] &&
   [[ -v TF_VAR_infisical_ro_secrets_path ]] && [[ -n "$TF_VAR_infisical_ro_secrets_path" ]] &&
   [[ -v TF_VAR_infisical_client_secret ]] && [[ -n "$TF_VAR_infisical_client_secret" ]]; then

  export INFISICAL_TOKEN=$(infisical login --method=universal-auth --domain="$TF_VAR_infisical_domain" --client-id="$TF_VAR_infisical_client_id" --client-secret="$TF_VAR_infisical_client_secret" --silent --plain)
  if [ $? -ne 0 ]; then
    echo -e "\033[31mZsh Warning: Infisical login failed.\033[0m"
    exit 1
  fi

  infisical export --domain="$TF_VAR_infisical_domain" --projectId="$TF_VAR_infisical_project_id" --path="$TF_VAR_infisical_ro_secrets_path" --format=dotenv-export > "$HOME/.infisical_exports.env"
  if [ $? -ne 0 ]; then
    echo -e "\033[31mZsh Warning: Infisical export failed.\033[0m"
    exit 1
  fi

else
  echo -e "\033[31mZsh Warning: One or more required Infisical environment variables are not set:\033[0m"
  if [[ ! -v TF_VAR_infisical_domain ]]; then echo -e "\033[31m  - TF_VAR_infisical_domain\033[0m"; fi
  if [[ ! -v TF_VAR_infisical_client_id ]]; then echo -e "\033[31m  - TF_VAR_infisical_client_id\033[0m"; fi
  if [[ ! -v TF_VAR_infisical_project_id ]]; then echo -e "\033[31m  - TF_VAR_infisical_project_id\033[0m"; fi
  if [[ ! -v TF_VAR_infisical_ro_secrets_path ]]; then echo -e "\033[31m  - TF_VAR_infisical_ro_secrets_path\033[0m"; fi
  if [[ ! -v TF_VAR_infisical_client_secret ]]; then echo -e "\033[31m  - TF_VAR_infisical_client_secret\033[0m"; fi
fi

exit 0
