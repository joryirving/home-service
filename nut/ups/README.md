# Network UPS Tools

https://networkupstools.org/

## Configuration

1. Install `nut` package and reboot

    ```sh
    sudo rpm-ostree install --idempotent --assumeyes nut
    sudo systemctl reboot
    ```

2. Create password in `./ups/password.secret`

3. Enable `nut` services

    ```sh
    task nut:bootstrap
    ```