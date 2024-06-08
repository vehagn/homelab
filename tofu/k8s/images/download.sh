#wget https://github.com/siderolabs/talos/releases/download/v1.7.4/nocloud-amd64.raw.xz
wget https://factory.talos.dev/image/dcac6b92c17d1d8947a0cee5e0e6b6904089aa878c70d66196bb1138dbd05d1a/v1.7.4/nocloud-amd64.raw.xz
xz -d nocloud-amd64.raw.xz
mv nocloud-amd64.raw talos-v1.7.4-nocloud-amd64.raw
