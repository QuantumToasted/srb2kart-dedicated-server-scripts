# srb2kart-dedicated-server-scripts
Scripts for quickly getting an SRB2Kart dedicated server up and running on Linux.
Each script is responsible for the following:
- Installing dependencies (including SRB2Kart!)
- Setting up an nginx webserver to host addons for users to download
- Setting the SRB2Kart server's `http_source` to the just-now-created nginx server
- Creating a server start script which handles Automagic™ addon discovery
- Creating a systemd service which automatically starts the server at boot and (attempts to) restart the server whenever it crashes

If the script executed successfully, you should have a now-running SRB2Kart server complete with an already-setup `http_source` pointing right back at the exact same machine the game is now installed in. A server script will be called every time the machine boots and if the server (successfully, at least) crashes/stops. However, due to SRB2Kart sometimes hanging instead of truly crashing, manual restarts will still be required via `sudo systemctl restart srb2kart.service`.

(More docs coming soon!)

## Quickstart
All scripts will function nearly identically, with some distro-specific quirks.
Once the script is running, follow any prompts that may pop up and select the appropriate response or answer when prompted.

### Ubuntu
```bash
wget -O setup.sh https://gitcdn.link/repo/QuantumToasted/srb2kart-dedicated-server-scripts/master/srb2kart-server-setup-ubuntu.sh
chmod +x setup.sh
sudo ./setup.sh
```
