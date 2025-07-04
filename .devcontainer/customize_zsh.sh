#!/bin/bash

# Get the workdir from the first argument
WRK_DIR="$1"

# Get the zshrc file path from the second argument
ZSHRC_FILE_PATH="$2"

ENV_FILE_PATH=$WRK_DIR/.env
INFISICAL_FILE_PATH=$WRK_DIR/.devcontainer/setup_infisical.sh
HOOKS_DIR_PATH=$WRK_DIR/hooks
INFISICAL_CLIENT_SECRET_FILE_PATH=$WRK_DIR/.devcontainer/infisical_secrets.env

cat <<EOF_ZSH_SETUP_ENV_FUNC >> "$ZSHRC_FILE_PATH"

_zsh_setup_homelab_env() {
  echo "Zsh: Setting up/refreshing Homelab environment..."

  # 1. Set Git Branch
  echo "Zsh: Setting GIT_BRANCH..."
  export GIT_BRANCH=\$(git symbolic-ref --short HEAD 2>/dev/null || echo 'unknown')
  echo "Zsh: GIT_BRANCH set to '\$GIT_BRANCH'"

  # 2. Set TF_VAR_gcs_env based on GIT_BRANCH
  echo "Zsh: Setting TF_VAR_gcs_env based on GIT_BRANCH ('\$GIT_BRANCH')..."
  if [ "\$GIT_BRANCH" = "main" ] || [ "\$GIT_BRANCH" = "prod" ]; then
    export TF_VAR_gcs_env="prod"
  elif [ "\$GIT_BRANCH" = "staging" ]; then
    export TF_VAR_gcs_env="staging"
  else
    export TF_VAR_gcs_env="dev"
  fi
  echo "Zsh: TF_VAR_gcs_env set to '\$TF_VAR_gcs_env'"

  # 3. Source .env file
  if [ -f "$ENV_FILE_PATH" ]; then
    echo "Zsh: Sourcing $ENV_FILE_PATH..."
    set -a
    . "$ENV_FILE_PATH"
    set +a
  else
    echo -e "\\033[31mZsh Warning: Environment file not found at: $ENV_FILE_PATH. Some environment variables may be missing.\\033[0m"
  fi

  # 4. Source Infisical client secret
  if [ -f "$INFISICAL_CLIENT_SECRET_FILE_PATH" ]; then
    echo "Zsh: Sourcing Infisical client secret from $INFISICAL_CLIENT_SECRET_FILE_PATH..."
    set -a
    . "$INFISICAL_CLIENT_SECRET_FILE_PATH"
    set +a
  else
    echo -e "\\033[31mZsh Warning: Infisical client secret file not found at: $INFISICAL_CLIENT_SECRET_FILE_PATH. TF_VAR_infisical_client_secret may not be set.\\033[0m"
  fi

  # 5. Run Infisical setup script
  if [ -f "$INFISICAL_FILE_PATH" ]; then
    echo "Zsh: Running Infisical setup script $INFISICAL_FILE_PATH..."
    chmod +x "$INFISICAL_FILE_PATH" >/dev/null 2>&1
    "$INFISICAL_FILE_PATH" # Script outputs its own messages/errors
    if [ -f "\$HOME/.infisical_exports.env" ]; then
      echo "Zsh: Sourcing Infisical output from \$HOME/.infisical_exports.env..."
      . "\$HOME/.infisical_exports.env"
      rm -f "\$HOME/.infisical_exports.env"
      echo "Zsh: Removed \$HOME/.infisical_exports.env"
    fi
  else
    echo -e "\\033[31mZsh Warning: Infisical setup script not found at: $INFISICAL_FILE_PATH. Infisical secrets might not be loaded.\\033[0m"
  fi

  # 6. Set Git Hooks Path
  if [ -d "$HOOKS_DIR_PATH" ]; then
    echo "Zsh: Setting Git hooks path to $HOOKS_DIR_PATH..."
    git config --local core.hooksPath "$HOOKS_DIR_PATH" >/dev/null 2>&1
  else
    echo -e "\\033[31mZsh Warning: Git hooks directory not found at: $HOOKS_DIR_PATH. Custom git hooks may not be active.\\033[0m"
  fi
  echo "Zsh: Homelab environment setup/refresh complete."
}
EOF_ZSH_SETUP_ENV_FUNC

cat <<'EOF_ZSH_INITIAL_CALL' >> "$ZSHRC_FILE_PATH"

# Initial setup for interactive Zsh shells
# Check for interactive shell using the most common method.
if [[ $- == *i* ]]; then
  if command -v _zsh_setup_homelab_env >/dev/null 2>&1; then
    _zsh_setup_homelab_env
  else
    echo -e "\033[31mZsh Warning: _zsh_setup_homelab_env function not found. Initial Homelab environment setup skipped.\033[0m"
  fi
fi
EOF_ZSH_INITIAL_CALL

cat <<'EOF_ZSH_PRECMD' >> "$ZSHRC_FILE_PATH"

# Zsh precmd hook to refresh environment on Git branch change
_zsh_hook_refresh_env_on_git_checkout() {
  local refresh_flag_file="$HOME/.needs_env_refresh" # Zsh's $HOME
  if [ -f "$refresh_flag_file" ]; then
    echo "Zsh: Detected Git branch change via flag file. Triggering environment setup..."
    # Call the centralized setup function
    if command -v _zsh_setup_homelab_env >/dev/null 2>&1; then
      _zsh_setup_homelab_env
    else
      echo -e "\033[31mZsh Warning: _zsh_setup_homelab_env function not found. Refresh on branch change skipped. Run 'source ~/.zshrc' manually.\033[0m"
    fi
    rm -f "$refresh_flag_file" # Remove flag after attempting refresh
  fi
}

# Add the refresh function to precmd_functions if not already present
if [[ -z "${precmd_functions[(r)_zsh_hook_refresh_env_on_git_checkout]}" ]]; then
  precmd_functions+=(_zsh_hook_refresh_env_on_git_checkout)
fi

EOF_ZSH_PRECMD
