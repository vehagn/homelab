# Innby

[Innby](https://github.com/vehagn/innby) RSVP site, from the chart at `oci://ghcr.io/vehagn/charts/innby`.

- Site: https://innby.s9n.no (external and internal gateway)
- Admin: https://innby.s9n.no/admin (internal gateway only)
- Games: https://innby-games.s9n.no (external and internal gateway)

## Secrets

The chart reads the `innby` Secret (see `secrets.example.env` in the Innby repo for the keys).
Seal it into `innby-credentials.yaml` (not `*secret*.yaml`, which is gitignored) and uncomment it in `kustomization.yaml`:

```shell
kubectl create secret generic innby --namespace innby \
  --from-env-file=secrets.env --dry-run=client --output=yaml \
  | kubeseal --controller-namespace sealed-secrets \
      --controller-name sealed-secrets-controller --format yaml \
  > innby-credentials.yaml
```

Keys: `INNBY_LINK_KEY`, `INNBY_ADMIN_JWT_SECRET` (both `openssl rand -base64 32`), `INNBY_ADMIN_PASSWORD_HASH`
(`innby hash-password`), `INNBY_SMTP_USER`, `INNBY_SMTP_PASSWORD`, and optionally `INNBY_OIDC_CLIENT_SECRET`.

## Game keys

Snake, Tetris and Balloon send scores from their own server, signed with a key derived from `INNBY_LINK_KEY`.
Without its key a game plays but keeps no scores; Reaction needs none. Once `innby-web` runs, print the keys
from it (it has the full config `game-key` needs), and seal them:

```shell
args=()
for game in snake tetris balloon; do
  key=$(kubectl exec -n innby deploy/innby-web -c innby -- /innby game-key $game) && [ -n "$key" ] \
    || { echo "no key for $game: is innby-web running?"; break; }
  args+=(--from-literal="INNBY_GAME_KEY_${game:u}=$key")
done
[ ${#args} -eq 3 ] && kubectl create secret generic innby-games --namespace innby \
  "${args[@]}" --dry-run=client --output=yaml \
  | kubeseal --controller-namespace sealed-secrets \
      --controller-name sealed-secrets-controller --format yaml \
  > innby-games-credentials.yaml
unset args key
```

Then uncomment `innby-games-credentials.yaml` in `kustomization.yaml`. The games read their keys at start, so after
a change run `kubectl -n innby rollout restart deploy/innby-games`; the log should no longer say "no INNBY_GAME_KEY".
A new link key means new game keys.
