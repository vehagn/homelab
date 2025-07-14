# Devcontainer

The `devcontainer.json` file uses a pre-built image based on the configuration in the `devcontainer-build.json` file.

Check available Devcontainer features at [https://containers.dev/features](https://containers.dev/features),
or edit the `Containerfile`.

**Disclaimer**: this is a fairly untested feature from the main author,
feedback is welcome.

## Getting started

Find the appropriate guide for your IDE, e.g.

* [IDEA](https://www.jetbrains.com/help/idea/start-dev-container-inside-ide.html)
* [VSCode](https://code.visualstudio.com/docs/devcontainers/containers)

Alternatively, you can start the devcontainer manually by running

```shell
docker run -it --rm \
  --user $(id -u):$(id -g) \
  --name homelab-devcontainer \
  --mount target=/tmp,type=tmpfs \
  --mount type=bind,src=.,dst=/workspace \
  --workdir /workspace \
  ghcr.io/vehagn/homelab-devcontainer:latest
```

from the project root.
