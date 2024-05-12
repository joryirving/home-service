# bws-cache

https://bitwarden.com/help/secrets-manager-cli/

## Configuration

1. Add your `ORG_ID` to `./containers/bws-cache/bws-cache.secret`

2. Create the podman secret

    ```sh
    sudo podman secret create org_id ./containers/bws-cache/bws-cache.secret
    ```

3. Start `bws-cache`
    ```sh
    task start-bws-cache
    ```
