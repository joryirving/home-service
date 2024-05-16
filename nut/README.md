# Network UPS Tools

https://networkupstools.org/

## Configuration

1. Install `nut` package and reboot

    ```sh
    sudo rpm-ostree install --reboot --idempotent --assumeyes nut
    ```

2. Create password in `./nut/ups/password.secret`

3. Enable `nut` services

    ```sh
    task nut:bootstrap
    ```