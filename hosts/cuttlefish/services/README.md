# Debugging
```sh
sudo machinectl shell keycloak
sudo journalctl -M keycloak
journalctl -u container@keycloak.service
To remove state: https://github.com/NixOS/nixpkgs/commit/3877ec5b2ff7436f4962ac0fe3200833cf78cb8b#commitcomment-19100105
```
