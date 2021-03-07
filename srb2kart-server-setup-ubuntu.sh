#!/bin/bash

# https://misc.flogisoft.com/bash/tip_colors_and_formatting
DIM="\e[2m"
UNDERLINE="\e[4m"
BLINK="\e[5m"
INVERT="\e[7m"
HIDDEN="\e[8m"
STRIKE="\e[9m"

RESET="\e[0m"
NOBOLD="\e[21m"
NODIM="\e[22m"
NOUNDERLINE="\e[24m"
NOBLINK="\e[25m"
NOINVERT="\e[27m"
NOHIDDEN="\e[28m"
NOSTRIKE="\e[29m"

# Foreground only
BLACK="\e[30m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
LIGHTGRAY="\e[37m"
DEFAULT="\e[39m"
DARKGRAY="\e[90m"
LIGHTRED="\e[91m"
LIGHTGREEN="\e[92m"
LIGHTYELLOW="\e[93m"
LIGHTBLUE="\e[94m"
LIGHTMAGENTA="\e[95m"
LIGHTCYAN="\e[96m"
WHITE="\e[97m"

user="${SUDO_USER}"
uid=$(id -u)
codename=$(lsb_release -sc 2>/dev/null)

print () {
    echo -ne "${1}${RESET}"
}

println () {
    echo -ne "${1}\n${RESET}"
}

die () {
    if [[ ! -z $1 ]] ; then
        println "${1}"
    fi

    println "${RED}Cancelling setup."
    exit 1
}

if [[ $uid -ne 0 ]] ; then
    die "${RED}This script must be run as the ${UNDERLINE}root${NOUNDERLINE} user (or via sudo)."
fi

if [[ -z $codename ]] ; then
    die "${RED}Your version codename could not be found. Are you sure you're running this script on Ubuntu?"
fi

println "Welcome to the SRB2Kart dedicated server setup script!"
println
sleep 1

print "Checking if the ${UNDERLINE}srb2kart${NOUNDERLINE} user exists..."
id -u "srb2kart" >/dev/null 2>&1

if [[ $? -eq 0 ]] ; then
    println "${GREEN}OK"
    print "Checking if the ${UNDERLINE}srb2kart${NOUNDERLINE} user has sudo access..."

    if [[ -z $(groups srb2kart | grep sudo) ]] ; then
        println "${YELLOW}NO ACCESS"
        print "Granting the ${UNDERLINE}srb2kart${NOUNDERLINE} user sudo access..."

        usermod -aG sudo srb2kart

        if [[ $? -ne 0 ]] ; then
            println
            die "${RED}Unable to properly grant root access."
        fi

        println "${GREEN}OK"
    fi
else
    println "${YELLOW}NOT FOUND"
    println "The ${UNDERLINE}srb2kart${NOUNDERLINE} user will now be created."
    println "Follow the on-screen prompts to continue."
    sleep 1
    println

    adduser srb2kart

    if [[ $? -ne 0 ]] ; then
        println
        die "${RED}An error occurred attempting to create the ${UNDERLINE}srb2kart${NOUNDERLINE} user."
    fi

    println
    print "Granting the ${UNDERLINE}srb2kart${NOUNDERLINE} user sudo access..."

    usermod -aG sudo srb2kart

    if [[ $? -ne 0 ]] ; then
        println
        die "${RED}Unable to properly grant root access."
    else
        println "${GREEN}OK"
    fi
fi

print "Creating directory /home/srb2kart/.srb2kart/addons/..."

if [[ ! -d "/home/srb2kart/.srb2kart/addons" ]] ; then
    mkdir -p "/home/srb2kart/.srb2kart/addons"

    if [[ $? -ne 0 ]] ; then
        println
        die "${RED}Could not create the directory /home/srb2kart/.srb2kart/addons."
    else
        println "${GREEN}OK"
    fi
else
    println "${GREEN}EXISTS"
fi

print "Making the ${UNDERLINE}srb2kart${NOUNDERLINE} user the owner of the folder..."

chown -R srb2kart:srb2kart "/home/srb2kart/.srb2kart"

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Unable to properly set ${UNDERLINE}srb2kart${NOUNDERLINE} as the owner."
else
    println "${GREEN}OK"
fi

println
println "User setup complete."
sleep 1

println
println "Checking prerequisites..."
println

print "srb2kart "
sleep 0.5
srb2k_needs_install=0
srb2k_executable_path=$(command -v srb2kart)

if [[ -z $srb2k_executable_path ]] ; then
    # SRB2Kart lives in /usr/games/ when installed via APT.
    # Because this isn't in the "secure_path" variable sudo uses,
    # we'll have to try to find it instead.
    srb2k_executable_path=$(find / -name srb2kart -type f -executable 2>/dev/null | head -n 1)
fi

# Do the same check, again, to see if it STILL wasn't found.
if [[ -z $srb2k_executable_path ]] ; then
    srb2k_needs_install=1
    println "${YELLOW}NOT FOUND"
else
    println "${GREEN}OK"
fi

# Everything else behaves nicely, so we don't need the extra nonsense.

print "screen "
sleep 0.5
screen_needs_install=0
screen_location=$(command -v screen)
if [[ -z $screen_location ]] ; then
    screen_needs_install=1
    println "${YELLOW}NOT FOUND"
else
    println "${GREEN}OK"
fi

print "curl "
sleep 0.5
curl_needs_install=0
if [[ -z $(command -v curl) ]] ; then
    curl_needs_install=1
    println "${YELLOW}NOT FOUND"
else
    println "${GREEN}OK"
fi

print "nginx "
sleep 0.5
nginx_needs_install=0
if [[ -z $(command -v nginx) ]] ; then
    nginx_needs_install=1
    println "${YELLOW}NOT FOUND"
else
    println "${GREEN}OK"
fi

println

if [[ $srb2k_needs_install -ne 0 || $curl_needs_install -ne 0 || $nginx_needs_install -ne 0  || $screen_needs_install -ne 0 ]] ; then
    println "${YELLOW}Required prerequisites missing or not installed."
    println
    println "One or more tools/programs required for setup were not found."
    println "This setup script will attempt to automatically install missing prerequisites,"
    println "however you may also decline, install them yourself, and then re-run this script."
    println

    read -p "Would you like to automatically install the missing prerequisites? (Y/n)" -n 1 -r answer
    println
    answer=${answer:-Y}

    if [[ ! $answer =~ ^[Yy]$ ]] ; then
        die
    fi

    print "Refreshing package list..."
    apt-get update >/dev/null

    if [[ $? -ne 0 ]] ; then
        println
        die "${RED}Failed to run ${UNDERLINE}apt-get update${NOUNDERLINE}."
    else
        println "${GREEN}OK"
    fi
fi

if [[ $srb2k_needs_install -ne 0 ]] ; then

    if [[ ! -d "/etc/apt/sources.list.d/" ]] ; then
        die "${RED}The folder /etc/apt/sources.list.d/ could not be located."
    fi

    print "Adding KartKrew's PPA to /etc/apt/sources.list.d/..."

    echo "deb http://ppa.launchpad.net/kartkrew/srb2kart/ubuntu ${codename} main" | tee "/etc/apt/sources.list.d/kartkrew-ubuntu-${codename}-srb2kart.list" >/dev/null
    echo "deb-src http://ppa.launchpad.net/kartkrew/srb2kart/ubuntu ${codename} main" | tee -a "/etc/apt/sources.list.d/kartkrew-ubuntu-${codename}-srb2kart.list" >/dev/null

    if [[ $? -ne 0 ]] ; then
        println
        die "${RED}Failed to add the PPA for some reason."
    else
        println "${GREEN}OK"
    fi

    print "Receiving KartKrew's GPG signing key..."

    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BC359FFF5A04B56C41DBC134289CABAB043F53A7 >/dev/null 2>&1

    if [[ $? -ne 0 ]] ; then
        println
        die "${RED}Failed to receive the signing key for some reason."
    else
        println "${GREEN}OK"
    fi

    print "Refreshing package list to retrieve KartKrew packages..."
    apt-get update >/dev/null

    if [[ $? -ne 0 ]] ; then
        println
        die "${RED}Failed to run ${UNDERLINE}apt-get update${NOUNDERLINE}. Try running it manually?"
    else
        println "${GREEN}OK"
    fi

    print "Installing SRB2Kart..."

    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=797071
    # Applies to ubuntu for some reason
    result_echo=$(apt-get -y install srb2kart 2>&1 >/dev/null)
    result=$?
    echo -n "${result_echo}" | grep -v "Extracting templates from packages"

    if [[ $result -ne 0 ]] ; then
        println
        die "${RED}Failed to run ${UNDERLINE}apt-get install srb2kart${NOUNDERLINE}. Try running it manually?"
    else
        println "${GREEN}OK"
    fi
fi

# This should always succeed if SRB2Kart successfully installed. If it doesn't...¯\_(ツ)_/¯
srb2k_data_dir=$(dirname $(readlink -f $(find / -name textures.kart -type f 2>/dev/null | head -n 1)))

srb2k_executable_path=$(command -v srb2kart)
if [[ -z $srb2k_executable_path ]] ; then
    # Same hacky workaround as before.
    srb2k_executable_path=$(find / -name srb2kart -type f -executable 2>/dev/null | head -n 1)
fi

if [[ $screen_needs_install -ne 0 ]] ; then
    print "Installing screen..."

    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=797071
    # Applies to ubuntu for some reason
    result_echo=$(apt-get -y install screen 2>&1 >/dev/null)
    result=$?
    echo -n "${result_echo}" | grep -v "Extracting templates from packages"

    if [[ $result -ne 0 ]] ; then
        println
        die "${RED}Failed to run ${UNDERLINE}apt-get install screen${NOUNDERLINE}. Try running it manually?"
    else
        println "${GREEN}OK"
    fi

    screen_location=$(command -v screen)
fi

if [[ $curl_needs_install -ne 0 ]] ; then
    print "Installing curl..."

    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=797071
    # Applies to ubuntu for some reason
    result_echo=$(apt-get -y install curl 2>&1 >/dev/null)
    result=$?
    echo -n "${result_echo}" | grep -v "Extracting templates from packages"

    if [[ $result -ne 0 ]] ; then
        println
        die "${RED}Failed to run ${UNDERLINE}apt-get install curl${NOUNDERLINE}. Try running it manually?"
    else
        println "${GREEN}OK"
    fi
fi

if [[ $nginx_needs_install -ne 0 ]] ; then
    print "Installing nginx..."

    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=797071
    # Applies to ubuntu for some reason
    result_echo=$(apt-get -y install nginx 2>&1 >/dev/null)
    result=$?
    echo -n "${result_echo}" | grep -v "Extracting templates from packages"

    if [[ $result -ne 0 ]] ; then
        println
        die "${RED}Failed to run ${UNDERLINE}apt-get install nginx${NOUNDERLINE}. Try running it manually?"
    else
        println "${GREEN}OK"
    fi
fi

println
println "Prerequisite check complete."
sleep 1

println
server_ipv4=$(curl -s "https://ipv4.icanhazip.com/")

if [[ -z $server_ipv4 ]] ; then
    println "${RED}Could not fetch your public IPv4."
    println "${RED}IPv4 is required for SRB2Kart networking functionality."
    die "${RED}Does your network maybe only support IPv6?"
else
    println "Your server's public IP is ${GREEN}${server_ipv4}"
fi

println
println "Configuring templates and settings..."
println

srb2k_template_complete=0

while [[ $srb2k_template_complete -eq 0 ]] ; do
    println "Configuring template: ${CYAN}kartserv.cfg"
    println "This template is a bare-minimum configuration file for your server."
    println

    read -p "Admin password (default: \"\" [no password]): " srb2k_password
    srb2k_password=$(echo "${srb2k_password}" | sed -r 's/[^a-zA-Z0-9!@#$%^&*()]//g')
    println

    read -p "Max number of players (default: 15 [1-15]): " srb2k_maxplayers
    srb2k_maxplayers="${srb2k_maxplayers:-15}"
    if [[ $srb2k_maxplayers -gt 15 || $srb2k_maxplayers -lt 1 ]] ; then
        srb2k_maxplayers="15"
    fi
    println

    read -p "Server name (default: SRB2Kart Server): " srb2k_servername
    srb2k_servername=$(echo "${srb2k_servername:-SRB2Kart Server}" | tr -d '"')
    println

    println "Setting http_source to your machine's public IP (${server_ipv4})."
    println

    kartserv_template=$(cat << KARTSERV
password "${srb2k_password}"
maxplayers "${srb2k_maxplayers}"
servername "${srb2k_servername}"
http_source "http://${server_ipv4}/"
KARTSERV
    )

    println "${CYAN}${kartserv_template}"
    println

    read -p "Does this template look correct? (Y/n)" -n 1 -r answer
    println
    answer=${answer:-Y}

    if [[ $answer =~ ^[Yy]$ ]] ; then
        srb2k_template_complete=1
    fi
done

print "Copying template to /home/srb2kart/.srb2kart/kartserv.cfg..."
echo "${kartserv_template}" | tee "/home/srb2kart/.srb2kart/kartserv.cfg" >/dev/null

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Failed to copy template."
else
    println "${GREEN}OK"
fi

print "Setting ${CYAN}srb2kart${RESET} as the owner of the file..."
chown srb2kart:srb2kart "/home/srb2kart/.srb2kart/kartserv.cfg"

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Failed to change the owner of /home/srb2kart/.srb2kart/kartserv.cfg."
else
    println "${GREEN}OK"
fi

println
println "Configuring template: ${CYAN}nginx server block"
println "This template currently does not require any interactive input."
println 

nginx_template=$(cat << NGINX
server {
    listen 80 default_server;

    root /home/srb2kart/.srb2kart/addons;

    index index.html;

    server_name _;

    location / {
        autoindex on;
    }
}
NGINX
)

print "Copying template to /etc/nginx/sites-available/default..."
echo "${nginx_template}" | tee "/etc/nginx/sites-available/default" >/dev/null

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Failed to copy template."
else
    println "${GREEN}OK"
fi

print "Reloading the nginx service to apply the template..."
systemctl reload nginx.service

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Failed to run ${UNDERLINE}systemctl reload nginx.service${NOUNDERLINE}."
else
    println "${GREEN}OK"
fi

println
println "Configuring template: ${CYAN}server.sh"
println "This template is responsible for starting the server."
println

bonuschars=0
read -p "Do you wish to enable bonuschars.kart? (Y/n)" -n 1 -r answer
println
answer=${answer:-Y}
if [[ $answer =~ ^[Yy]$ ]] ; then
    bonuschars=1
fi

advertise=0
read -p "Do you wish to publicly advertise this server? (Y/n)" -n 1 -r answer
println
answer=${answer:-Y}
if [[ $answer =~ ^[Yy]$ ]] ; then
    advertise=1
fi

serverscript_template=$(cat << 'SERVER'
#!/bin/bash
use_bonuschars=%BONUSCHARS%
addons_raw=$(cd /home/srb2kart/.srb2kart/addons && find -type f -print | sed "s|^\./||")
addons=$(echo "${addons_raw}" | tr '\n' ' ')
addon_count=$(tr -dc ' ' <<< $addons | wc -c)
echo "Found ${addon_count} extra addon(s):"
echo "${addons_raw}"

if [[ $use_bonuschars -eq 1 ]] ; then
    %SRB2KPATH% +advertise %ADVERTISE% -dedicated -file bonuschars.kart $addons
else
    %SRB2KPATH% +advertise %ADVERTISE% -dedicated -file $addons
fi
SERVER
)

# Using | instead of / as delimiter because paths will have / in them
serverscript_template=$(echo "${serverscript_template}" | sed "s|%BONUSCHARS%|${bonuschars}|g" | sed "s|%SRB2KPATH%|${srb2k_executable_path}|g" | sed "s|%ADVERTISE%|${advertise}|g")

print "Copying template to ${srb2k_data_dir}/server.sh..."
echo "${serverscript_template}" | tee "${srb2k_data_dir}/server.sh" >/dev/null

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Failed to copy template."
else
    println "${GREEN}OK"
fi

print "Setting ${CYAN}srb2kart${RESET} as the owner of the file..."
chown srb2kart:srb2kart "${srb2k_data_dir}/server.sh"

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Failed to change the owner of ${srb2k_data_dir}/server.sh."
else
    println "${GREEN}OK"
fi

print "Marking file as executable..."
chmod +x "${srb2k_data_dir}/server.sh"

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Failed to chmod +x ${srb2k_data_dir}/server.sh."
else
    println "${GREEN}OK"
fi

println
println "Configuring template: ${CYAN}srb2kart.service"
println

read -p $'Restart service when program exits (\e[4malways\e[24m/on-failure): ' service_restart
println
service_restart=$($service_restart | tr [:upper:] [:lower:])
if [[ $service_restart != "always" && $service_restart != "on-failure" ]] ; then
    service_restart="always"
fi

read -p $'Screen (background terminal) window name? (default is \e[36mkart\e[0m): ' screen_windowname
println
screen_windowname=$(echo "${screen_windowname:-kart}" | sed -r 's/[^a-zA-Z0-9]//g')

systemd_template=$(cat << SYSTEMD
[Unit]
Description=SRB2Kart Server
After=network.target

[Service]
Type=forking
ExecStart=${screen_location} -S ${screen_windowname} -dm ${srb2k_data_dir}/server.sh
Restart=${service_restart}
User=srb2kart

[Install]
WantedBy=multi-user.target
SYSTEMD
)

print "Copying template to /etc/systemd/system/srb2kart.service..."
echo "${systemd_template}" | tee "/etc/systemd/system/srb2kart.service" >/dev/null

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Failed to copy template."
else
    println "${GREEN}OK"
fi

print "Enabling systemd service ${CYAN}srb2kart.service..."
systemctl enable srb2kart.service >/dev/null

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Failed to run systemctl enable srb2kart.service${NOUNDERLINE}."
else
    println "${GREEN}OK"
fi

print "Starting systemd service ${CYAN}srb2kart.service..."
systemctl start srb2kart.service

if [[ $? -ne 0 ]] ; then
    println
    die "${RED}Failed to run systemctl start srb2kart.service${NOUNDERLINE}."
else
    println "${GREEN}OK"
fi

println
println "${GREEN}Setup complete!"