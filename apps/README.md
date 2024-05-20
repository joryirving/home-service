# apps

## bind

<https://www.isc.org/bind/>

### bind configuration

> [!IMPORTANT]
> _**Do not** modify the key contents after it's creation, instead create a new key using `tsig-keygen`._
1. Create the base rndc key and encrypt it with sops

    ```sh
    tsig-keygen -a hmac-sha256 rndc-key > ./apps/bind/data/config/rndc.sops.key
    sops --encrypt --in-place ./apps/bind/data/config/rndc.sops.key
    ```

2. [Optional] Create additional rndc keys for external-dns and encrypt them with sops

3. Update `./apps/bind/data/config` with your configuration

## Optional configuration

1. Create additional rndc keys for external-dns and encrypt them with sops

    ```sh
    tsig-keygen -a hmac-sha256 kubernetes-main-key > ./apps/bind/data/config/kubernetes-main.sops.key
    sops --encrypt --in-place ./apps/bind/data/config/kubernetes-main.sops.key
    ```

## blocky

<https://github.com/0xERR0R/blocky>

### blocky configuration

> [!IMPORTANT]
> _Blocky can take awhile to start depending on how many blocklists you have configured_
1. Update `./apps/blocky/data/config/config.yaml` with your configuration and then start the stack

    ```sh
    task dns-start-primary
    ```

## bws-cache

<https://bitwarden.com/help/secrets-manager-cli/>

## Configuration

1. Add your `ORG_ID` to `./apps/bws-cache/data/config/config.sops.env`

2. Start `bws-cache`
    ```sh
    task start-bws-cache
    ```

## podman-exporter

<https://github.com/containers/prometheus-podman-exporter>

### Configuration

1. Enable the `podman.socket` service

    ```sh
    sudo systemctl enable --now podman.socket
    ```

2. Start `podman-exporter`

    ```sh
    task start-podman-exporter
    ```