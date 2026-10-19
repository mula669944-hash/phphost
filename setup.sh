#!/bin/bash
set -e

# Auto-Escalate to Sudo if not root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[1;33m[!] Elevated permissions required. Re-running with sudo...\e[0m"
  exec sudo bash "$0" "$@"
fi

# ====================================================================
# 🎨 COLOR PALETTE & STYLES
# ====================================================================
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"
CYAN="\e[1;36m"
WHITE="\e[1;37m"
RESET="\e[0m"
BOLD="\e[1m"

# ====================================================================
# 🚀 STYLISH BANNER FUNCTION
# ====================================================================
show_banner() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}██████╗ ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗"
    echo -e "██╔══██╗██╔══██╗██║  ██║██╔═══██╗██╔════╝╚══██╔══╝"
    echo -e "██████╔╝██████╔╝███████║██║   ██║███████╗   ██║   "
    echo -e "██╔══██╗██╔══██╗██╔══██║██║   ██║╚════██║   ██║   "
    echo -e "██║  ██║██║  ██║██║  ██║╚██████╔╝███████║   ██║   "
    echo -e "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   ${RESET}"
    echo -e "${YELLOW}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}        ⚡  R R H O S T   C L O U D   M A N A G E R  ⚡${RESET}"
    echo -e "${WHITE}        Dev: ${CYAN}Rafi${WHITE}  |  Version: ${YELLOW}2.6 Pro${WHITE}  |  System: ${GREEN}Active${WHITE}        ${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# ====================================================================
# 🛠️ FEATURE 1: FRESH INSTALLATION
# ====================================================================
install_server() {
    echo -e "${YELLOW}${BOLD}[*] Fresh Server Setup Initialization:${RESET}\n"

    while [ -z "$MY_DOMAIN" ]; do
        echo -en "${CYAN}[?] Enter Domain Name ${WHITE}(e.g. site.up.railway.app): ${GREEN}"
        read -r MY_DOMAIN
        echo -en "${RESET}"
        MY_DOMAIN=$(echo "$MY_DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        if [ -z "$MY_DOMAIN" ]; then
            echo -e "${RED}[!] Domain cannot be empty!${RESET}"
        fi
    done

    echo -en "${CYAN}[?] Enter Site Folder Name ${WHITE}[Default: mango]: ${GREEN}"
    read -r MY_FOLDER
    echo -en "${RESET}"
    MY_FOLDER=${MY_FOLDER:-mango}

    echo -en "${CYAN}[?] Enter Database Username ${WHITE}[Default: admin]: ${GREEN}"
    read -r DB_USER
    echo -en "${RESET}"
    DB_USER=${DB_USER:-admin}

    while [ -z "$DB_PASS" ]; do
        echo -en "${CYAN}[?] Enter Database Password: ${GREEN}"
        read -r DB_PASS
        echo -en "${RESET}"
        if [ -z "$DB_PASS" ]; then
            echo -e "${RED}[!] Password cannot be empty!${RESET}"
        fi
    done

    echo ""
    echo -e "${GREEN}✔ Configuration Saved. Deploying Server...${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"

    export DEBIAN_FRONTEND=noninteractive

    echo -e "${YELLOW}[>] STEP 1/8:${RESET} Updating packages & PHP repository..."
    apt-get update -qq
    apt-get install -y -qq lsb-release ca-certificates apt-transport-https curl unzip psmisc mariadb-server python3 python3-pip python3-venv > /dev/null 2>&1
    curl -sSLo /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
    apt-get update -qq

    echo -e "${YELLOW}[>] STEP 2/8:${RESET} Installing Apache2 & PHP 8.1 Stack..."
    apt-get install -y -qq apache2 php8.1 libapache2-mod-php8.1 php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip php8.1-bcmath > /dev/null 2>&1

    echo -e "${YELLOW}[>] STEP 3/8:${RESET} Installing ionCube Loader..."
    cd /tmp
    curl -sSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o ioncube.tar.gz
    tar -xzf ioncube.tar.gz
    rm -rf /usr/local/ioncube
    mv ioncube /usr/local/
    rm -f ioncube.tar.gz
    echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_8.1.so" > /etc/php/8.1/mods-available/ioncube.ini
    ln -sf /etc/php/8.1/mods-available/ioncube.ini /etc/php/8.1/apache2/conf.d/00-ioncube.ini
    ln -sf /etc/php/8.1/mods-available/ioncube.ini /etc/php/8.1/cli/conf.d/00-ioncube.ini
    phpdismod -v 8.1 opcache 2>/dev/null || true

    echo -e "${YELLOW}[>] STEP 4/8:${RESET} Setting up MariaDB Server..."
    service mariadb start > /dev/null 2>&1
    mariadb -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'; GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"

    echo -e "${YELLOW}[>] STEP 5/8:${RESET} Deploying phpMyAdmin Core..."
    mkdir -p /var/www/html/phpmyadmin
    curl -sSL https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz -o /tmp/pma.tar.gz
    tar -xzf /tmp/pma.tar.gz -C /var/www/html/phpmyadmin --strip-components=1
    rm -f /tmp/pma.tar.gz

    echo -e "${YELLOW}[>] STEP 6/8:${RESET} Setting up Online File Manager..."
    mkdir -p /var/www/html/filemanager
    curl -sSL https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php -o /var/www/html/filemanager/index.php

    echo -e "${YELLOW}[>] STEP 7/8:${RESET} Configuring Apache Routing & VHost..."
    mkdir -p /var/www/html/$MY_FOLDER
    mkdir -p /var/www/html/$MY_FOLDER/TelegramBotHost
    APP_PORT=${PORT:-80}
    echo "Listen $APP_PORT" > /etc/apache2/ports.conf

    a2enmod rewrite headers setenvif mpm_prefork php8.1 2>/dev/null || true
    a2dismod mpm_event mpm_worker 2>/dev/null || true
    sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

    # সেভ ডোমেন ও ফোল্ডার ইনফো ফর ফিউচার চেঞ্জ
    echo "MY_FOLDER=$MY_FOLDER" > /etc/rrhost.conf
    echo "DB_USER=$DB_USER" >> /etc/rrhost.conf
    echo "MY_DOMAIN=$MY_DOMAIN" >> /etc/rrhost.conf

    cat << EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:$APP_PORT>
    ServerName $MY_DOMAIN
    ServerAlias www.$MY_DOMAIN

    SetEnvIf X-Forwarded-Proto "^https$" HTTPS=on
    UseCanonicalName Off
    UseCanonicalPhysicalPort Off

    DocumentRoot /var/www/html/$MY_FOLDER

    <Directory /var/www/html/$MY_FOLDER>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    Alias /filemanager /var/www/html/filemanager
    <Directory /var/www/html/filemanager>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    Alias /phpmyadmin /var/www/html/phpmyadmin
    <Directory /var/www/html/phpmyadmin>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

    cat << 'EOF' > /var/www/html/$MY_FOLDER/index.php
<?php
// System Live Checks
$php_version = phpversion();
$ioncube_loaded = extension_loaded('ionCube Loader') ? 'Active (v' . ioncube_loader_version() . ')' : 'Not Loaded';
$mysql_status = class_exists('mysqli') ? 'Ready & Supported' : 'Missing Extension';
$server_ip = $_SERVER['SERVER_ADDR'] ?? 'Railway Container';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RRHOST - Cloud Engine Dashboard</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
        body { background: #0d1117; color: #c9d1d9; display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 20px; }
        .card { background: #161b22; border: 1px solid #30363d; border-radius: 14px; max-width: 680px; width: 100%; padding: 35px; box-shadow: 0 12px 35px rgba(0,0,0,0.5); }
        .header { text-align: center; border-bottom: 1px solid #30363d; padding-bottom: 25px; margin-bottom: 25px; }
        .badge { display: inline-block; background: #238636; color: #fff; font-size: 12px; font-weight: 700; padding: 4px 12px; border-radius: 20px; text-transform: uppercase; margin-bottom: 12px; letter-spacing: 1px; }
        h1 { color: #58a6ff; font-size: 26px; margin-bottom: 8px; }
        p.subtitle { color: #8b949e; font-size: 14px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 30px; }
        @media(max-width: 550px) { .grid { grid-template-columns: 1fr; } }
        .stat-box { background: #0d1117; border: 1px solid #21262d; border-radius: 8px; padding: 14px 18px; }
        .stat-label { font-size: 12px; color: #8b949e; text-transform: uppercase; letter-spacing: 0.5px; }
        .stat-value { font-size: 15px; color: #f0f6fc; font-weight: 600; margin-top: 4px; }
        .stat-value.ok { color: #3fb950; }
        .btn-group { display: flex; gap: 12px; flex-wrap: wrap; }
        .btn { flex: 1; min-width: 140px; text-align: center; text-decoration: none; padding: 12px 16px; border-radius: 8px; font-size: 14px; font-weight: 600; transition: all 0.2s; }
        .btn-pma { background: #1f6feb; color: #ffffff; border: 1px solid #388bfd; }
        .btn-pma:hover { background: #388bfd; }
        .btn-fm { background: #238636; color: #ffffff; border: 1px solid #2ea043; }
        .btn-fm:hover { background: #2ea043; }
        .footer { text-align: center; margin-top: 25px; font-size: 12px; color: #484f58; border-top: 1px solid #21262d; padding-top: 15px; }
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <span class="badge">🚀 All Systems Operational</span>
            <h1>RRHOST Cloud Stack</h1>
            <p class="subtitle">Complete PHP 8.1, MariaDB & Web Engine Successfully Configured</p>
        </div>

        <div class="grid">
            <div class="stat-box">
                <div class="stat-label">Web Engine</div>
                <div class="stat-value ok">Apache 2.4 (Live)</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">PHP Runtime</div>
                <div class="stat-value ok">PHP <?= $php_version; ?></div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Database Engine</div>
                <div class="stat-value ok">MariaDB Server (Running)</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Security & Loader</div>
                <div class="stat-value ok">ionCube <?= $ioncube_loaded; ?></div>
            </div>
            <div class="stat-box">
                <div class="stat-label">App Directory</div>
                <div class="stat-value">/var/www/html/<?= basename(__DIR__); ?></div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Python Bot Host</div>
                <div class="stat-value ok">Python 3 + venv Ready</div>
            </div>
        </div>

        <div class="btn-group">
            <a href="/phpmyadmin" class="btn btn-pma" target="_blank">🗄️ Open phpMyAdmin</a>
            <a href="/filemanager" class="btn btn-fm" target="_blank">📁 TinyFileManager</a>
        </div>

        <div class="footer">
            Managed by RRHOST Manager &bull; Developer Rafi
        </div>
    </div>
</body>
</html>
EOF

    echo -e "${YELLOW}[>] STEP 8/8:${RESET} Applying Permissions & Launching..."
    chmod -R 775 /var/www/html
    chown -R www-data:www-data /var/www/html
    service mariadb restart > /dev/null 2>&1

    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${GREEN}${BOLD}             🎉  DEPLOYMENT SUCCESSFUL  🎉                    ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}🌐 WEBSITE DETAILS:${RESET}"
    echo -e "    • Public URL    : ${CYAN}https://$MY_DOMAIN${RESET}"
    echo -e "    • Root Directory: ${YELLOW}/var/www/html/$MY_FOLDER${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}🗄️ DATABASE (phpMyAdmin):${RESET}"
    echo -e "    • Login URL     : ${CYAN}https://$MY_DOMAIN/phpmyadmin${RESET}"
    echo -e "    • User          : ${YELLOW}$DB_USER${RESET}"
    echo -e "    • Password      : ${YELLOW}$DB_PASS${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}📁 FILE MANAGER (TinyFileManager):${RESET}"
    echo -e "    • Access URL    : ${CYAN}https://$MY_DOMAIN/filemanager${RESET}"
    echo -e "    • Default User  : ${YELLOW}admin${RESET}"
    echo -e "    • Default Pass  : ${YELLOW}admin@123${RESET}"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}[✔] RRHOST Engine is LIVE and Running in Foreground.${RESET}"
    echo -e "${YELLOW}[!] Keep this terminal open to maintain uptime.${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"

    rm -f /var/run/apache2/apache2.pid
    exec apache2ctl -D FOREGROUND
}

# ====================================================================
# 🔄 FEATURE 2: CHANGE DOMAIN (INSTANT 2 SECONDS UPDATE)
# ====================================================================
change_domain() {
    echo -e "${YELLOW}${BOLD}[*] Instant Domain Switcher:${RESET}\n"

    while [ -z "$NEW_DOMAIN" ]; do
        echo -en "${CYAN}[?] Enter NEW Domain Name ${WHITE}(e.g. newdomain.com): ${GREEN}"
        read -r NEW_DOMAIN
        echo -en "${RESET}"
        NEW_DOMAIN=$(echo "$NEW_DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    done

    echo -e "\n${YELLOW}[>] Updating VirtualHost configuration...${RESET}"
    sed -i "s/ServerName .*/ServerName $NEW_DOMAIN/" /etc/apache2/sites-available/000-default.conf
    sed -i "s/ServerAlias www\..*/ServerAlias www.$NEW_DOMAIN/" /etc/apache2/sites-available/000-default.conf

    echo -e "${YELLOW}[>] Reloading Apache Engine...${RESET}"
    apache2ctl graceful > /dev/null 2>&1 || service apache2 restart > /dev/null 2>&1

    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}✔ Domain Successfully Changed!${RESET}"
    echo -e "🔗 New Website URL : ${CYAN}https://$NEW_DOMAIN${RESET}"
    echo -e "🔗 New phpMyAdmin  : ${CYAN}https://$NEW_DOMAIN/phpmyadmin${RESET}"
    echo -e "🔗 New FileManager : ${CYAN}https://$NEW_DOMAIN/filemanager${RESET}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}\n"
    exit 0
}

# ====================================================================
# 🔑 FEATURE 3: RESET DATABASE PASSWORD
# ====================================================================
reset_db_pass() {
    echo -e "${YELLOW}${BOLD}[*] Reset Database User Password:${RESET}\n"

    echo -en "${CYAN}[?] Database Username ${WHITE}[Default: admin]: ${GREEN}"
    read -r TARGET_USER
    TARGET_USER=${TARGET_USER:-admin}

    while [ -z "$NEW_PASS" ]; do
        echo -en "${CYAN}[?] Enter NEW Database Password: ${GREEN}"
        read -r NEW_PASS
        echo -en "${RESET}"
    done

    echo -e "\n${YELLOW}[>] Updating database privileges...${RESET}"
    service mariadb start > /dev/null 2>&1
    mariadb -e "ALTER USER '$TARGET_USER'@'localhost' IDENTIFIED BY '$NEW_PASS'; FLUSH PRIVILEGES;"

    echo -e "${GREEN}✔ Password updated successfully for user: ${YELLOW}$TARGET_USER${RESET}\n"
    exit 0
}

# ====================================================================
# 🤖 FEATURE 5: DEPLOY & RUN TELEGRAM BOT
# ====================================================================
deploy_telegram_bot() {
    echo -e "${YELLOW}${BOLD}[*] Telegram Bot Automated Runner:${RESET}\n"

    if [ -f /etc/rrhost.conf ]; then
        source /etc/rrhost.conf
    fi
    MY_FOLDER=${MY_FOLDER:-mango}

    BOT_DIR="/var/www/html/$MY_FOLDER/TelegramBotHost"

    if [ ! -d "$BOT_DIR" ]; then
        echo -e "${RED}[!] Bot directory not found at: $BOT_DIR${RESET}"
        echo -e "${YELLOW}[*] Creating directory... Please upload your bot files via File Manager.${RESET}"
        mkdir -p "$BOT_DIR"
    fi

    cd "$BOT_DIR"

    echo -e "${YELLOW}[>] Setting up Python Virtual Environment...${RESET}"
    python3 -m venv venv > /dev/null 2>&1
    source venv/bin/activate

    if [ -f "requirements.txt" ]; then
        echo -e "${YELLOW}[>] Installing dependencies from requirements.txt...${RESET}"
        pip install --upgrade pip > /dev/null 2>&1
        pip install -r requirements.txt
    else
        echo -e "${YELLOW}[>] Installing standard libraries...${RESET}"
        pip install --upgrade pip > /dev/null 2>&1
        pip install pyrogram tgcrypto python-telegram-bot apscheduler requests > /dev/null 2>&1 || true
    fi

    # পুরানো কোনো বট চললে বন্ধ করা
    pkill -f main.py 2>/dev/null || true

    echo -e "${YELLOW}[>] Starting Bot in background...${RESET}"
    nohup python3 main.py > bot.log 2>&1 &

    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}✔ Telegram Bot Successfully Started!${RESET}"
    echo -e "📁 Path : ${CYAN}$BOT_DIR${RESET}"
    echo -e "📄 Log  : ${CYAN}$BOT_DIR/bot.log${RESET}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}\n"

    # নিশ্চিত করা Apache এবং MySQL ব্যাকগ্রাউন্ডে চলছে কিনা
    service mariadb status >/dev/null 2>&1 || service mariadb start >/dev/null 2>&1
    service apache2 status >/dev/null 2>&1 || service apache2 start >/dev/null 2>&1

    echo -e "${CYAN}[?] Do you want to view live logs? (y/n): ${GREEN}"
    read -r VIEW_LOG
    if [[ "$VIEW_LOG" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        tail -f bot.log
    fi
    exit 0
}

# ====================================================================
# ⚡ FEATURE 6: START ALL SERVERS (FULL ENGINE RUNNER)
# ====================================================================
start_all_services() {
    echo -e "${YELLOW}${BOLD}[*] Starting All Services (Apache, MariaDB & Bot)...${RESET}\n"

    # ১. ডেটাবেস স্টার্ট
    echo -e "${YELLOW}[>] Starting MariaDB...${RESET}"
    service mariadb restart > /dev/null 2>&1

    # ২. টেলিগ্রাম বট স্টার্ট (যদি থাকে)
    if [ -f /etc/rrhost.conf ]; then
        source /etc/rrhost.conf
    fi
    MY_FOLDER=${MY_FOLDER:-mango}
    BOT_DIR="/var/www/html/$MY_FOLDER/TelegramBotHost"

    if [ -f "$BOT_DIR/main.py" ]; then
        echo -e "${YELLOW}[>] Starting Telegram Bot...${RESET}"
        cd "$BOT_DIR"
        source venv/bin/activate 2>/dev/null || true
        pkill -f main.py 2>/dev/null || true
        nohup python3 main.py > bot.log 2>&1 &
        echo -e "${GREEN}✔ Bot Started in background!${RESET}"
    fi

    # ৩. Apache চালু করা Foreground মোডে (যাতে Railway সার্ভার অফ না হয়)
    echo -e "${YELLOW}[>] Launching Apache Server in Foreground...${RESET}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}✔ All Services (Apache, DB, Bot) are now ONLINE!${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"
    
    rm -f /var/run/apache2/apache2.pid
    exec apache2ctl -D FOREGROUND
}

# ====================================================================
# 🎛️ MAIN CONTROL MENU
# ====================================================================
show_banner

echo -e "${BOLD}${WHITE}Select an action from below:${RESET}"
echo -e "   ${GREEN}[1]${RESET} Fresh Install Server      ${WHITE}(Complete Setup)${RESET}"
echo -e "   ${YELLOW}[2]${RESET} Change Domain Name        ${WHITE}(Instant 2-Sec Update)${RESET}"
echo -e "   ${CYAN}[3]${RESET} Reset DB Password         ${WHITE}(Change MySQL Pass)${RESET}"
echo -e "   ${MAGENTA}[4]${RESET} Restart Engine            ${WHITE}(Reboot Apache & MySQL)${RESET}"
echo -e "   ${BLUE}[5]${RESET} Deploy & Run Telegram Bot ${WHITE}(Auto venv & Run main.py)${RESET}"
echo -e "   ${GREEN}${BOLD}[6]${RESET} Start All Servers         ${BOLD}${WHITE}(Apache + DB + Bot Foreground)${RESET}"
echo -e "   ${RED}[0]${RESET} Exit"
echo ""
echo -en "${CYAN}[?] Choose option [0-6]: ${GREEN}"
read -r CHOICE
echo -e "${RESET}"

case $CHOICE in
    1)
        install_server
        ;;
    2)
        change_domain
        ;;
    3)
        reset_db_pass
        ;;
    4)
        echo -e "${YELLOW}[>] Restarting Apache and MariaDB...${RESET}"
        service mariadb restart
        service apache2 restart
        echo -e "${GREEN}✔ All Services Restarted!${RESET}"
        ;;
    5)
        deploy_telegram_bot
        ;;
    6)
        start_all_services
        ;;
    0)
        echo -e "${RED}[*] Exiting installer. Goodbye!${RESET}"
        exit 0
        ;;
    *)
        echo -e "${RED}[!] Invalid option selected.${RESET}"
        exit 1
        ;;
esac
