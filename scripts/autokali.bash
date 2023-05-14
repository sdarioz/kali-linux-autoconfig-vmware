#!/bin/bash

#####################################################################
###### Auto Kali Linux config                                  ######
###### Intended for their use at the first fresh install       ######
###### Version: 1.0 rev 1                                      ######
######                                                         ######
###### Notes: Focused on VMWare.                               ######
#####################################################################

# CHANGELOG:
#
# (26/01/2023)* First commit
# (02/04/2023)* Modified rkhunter and samhain cronjob code for better readability 

# Global Variables
col_reset='\033[0m'
col_red='\033[0;31m'
col_green="\033[1;32m"
col_yellow="\033[1;33m"
col_magenta="\033[1;35m"
col_cyan='\033[0;36m'
col_backg_cyan='\033[46m'

# Ensure root
if [[ $(id -u) -ne 0 ]]; then
    printf "Please run as root.\n"
    exit 1
fi

# PWD to working directory string
working_dir=$(pwd)

# Loading animation
function load_animation() {
    printf '⋮ \r'
    sleep 0.3
    printf '⋮ ⋰ ⋯ ⋱ \r'
    sleep 0.3
    printf '⋮ ⋰ ⋯ ⋱ ⋮ \r'
    sleep 0.5
    printf '⋮ ⋰ ⋯ ⋱ ⋮ ✓\r'
    printf '\n'
}

# Spinner
function loading_spinner() {
    # $1 start/stop
    #
    # on start: $2 display message
    # on stop : $2 process exit status
    #           $3 spinner function pid (supplied from stop_spinner)

    local on_success="DONE"
    local on_fail="FAIL"
    local white="\e[1;37m"
    local green="\e[1;32m"
    local red="\e[1;31m"
    local nc="\e[0m"

    case $1 in
        start)
            # calculate the column where spinner and status msg will be displayed
            let column=$(tput cols)-${#2}-8
            # display message and position the cursor in $column column
            printf "${2}"
            printf "%${column}s"

            # start spinner
            i=1
            sp='\|/-'
            delay=${SPINNER_DELAY:-0.15}

            while :; do
                printf "\b${sp:i++%${#sp}:1}"
                sleep $delay
            done
            ;;
        stop)
            if [[ -z ${3} ]]; then
                echo "spinner is not running.."
                exit 1
            fi

            kill $3 >/dev/null 2>&1

            # inform the user upon success or failure
            echo -en "\b["
            if [[ $2 -eq 0 ]]; then
                echo -en "${green}${on_success}${nc}"
            else
                echo -en "${red}${on_fail}${nc}"
            fi
            echo -e "]"
            ;;
        *)
            echo "invalid argument, try {start/stop}"
            exit 1
            ;;
    esac
}

# shellcheck disable=SC2120
function start_spinner() {
    # $1 : msg to display
    loading_spinner "start" "${1}" &
    # set global spinner pid
    sp_pid=$!
    disown
}

function stop_spinner() {
    # $1 : command exit status
    loading_spinner "stop" $1 $sp_pid
    unset sp_pid
}

# Advanced Security Hardening
function advanced_security_hardening() {

    printf "${col_green}Setting up advanced security hardening...${col_reset}\n"
    load_animation

    printf "${col_green}Installing and configuring Samhain...${col_reset}\n"


    # Install Samhain
    apt-get install samhain -y

    # The following adjustments for Samhain are optimized for VMWare and Kali Linux.

    # Copy the default configuration file to a local file
    cp /etc/samhain/samhainrc /etc/samhain/samhainrc.local

    # Set the database directory
    sed -i 's/^# DBDIR.*/DBDIR \/var\/lib\/samhain/' /etc/samhain/samhainrc.local

    # Set the log file
    sed -i 's/^# LOGFILE.*/LOGFILE \/var\/log\/samhain.log/' /etc/samhain/samhainrc.local

    # Set the log file permissions
    sed -i 's/^# LOGMODE.*/LOGMODE 0640/' /etc/samhain/samhainrc.local

    # Set the log facility
    sed -i 's/^# LOGFACILITY.*/LOGFACILITY local0/' /etc/samhain/samhainrc.local

    # Enable syslog, in Kali Linux the default is disabled
    sed -i 's/^# SYSLOG.*/SYSLOG yes/' /etc/samhain/samhainrc.local

    # Set the syslog facility
    sed -i 's/^# SYSLOG_FACILITY.*/SYSLOG_FACILITY local0/' /etc/samhain/samhainrc.local

    # Set the syslog level, 5 is the default and the highest
    sed -i 's/^# SYSLOG_LEVEL.*/SYSLOG_LEVEL 5/' /etc/samhain/samhainrc.local

    # Tripwire
    printf "${col_green}Installing and configuring Tripwire...${col_reset}\n"
    apt-get install tripwire -y

    # Configuring Tripwire

    # Copy the default configuration file to a local file
    cp /etc/tripwire/twpol.txt /etc/tripwire/twpol.txt.local

    # Set the site key, the site key is used to identify the site that Tripwire is monitoring
    # sed -i 's/^# SITEKEY.*/SITEKEY 1234567890/' /etc/tripwire/twpol.txt.local

    # Set the local host name, the local host name is used to identify the host that Tripwire is monitoring
    sed -i 's/^# LOCALHOST.*/LOCALHOST '${USER}'/' /etc/tripwire/twpol.txt.local

    # Tripwire is for file integrity monitoring and also for detecting changes in the system.

    # Lynis
    printf "${col_green}Installing and configuring Lynis...${col_reset}\n"
    apt-get install lynis -y


    # Secure user account settings
    printf "${col_green}Securing user account settings...${col_reset}\n"

    # Set the maximum number of days a password may be used
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs

    # Set the minimum number of days allowed between password changes
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs

    # Set the number of days warning given before a password expires
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs


    # Configure log monitoring with logwatch
    printf "${col_green}Configuring log monitoring...${col_reset}\n"
    apt-get install logwatch -y

    # Configure logwatch

    # Set the email address to send the logwatch report to
    echo "MailTo = deepmuscle@proton.me" > /etc/logwatch/conf/logwatch.conf

    # Set the email address to send the logwatch report from
    echo "MailFrom = Logwatch" >> /etc/logwatch/conf/logwatch.conf

    # Set the range of the report to yesterday
    echo "Range = yesterday" >> /etc/logwatch/conf/logwatch.conf

     # Set the detail level of the report to medium
    echo "Detail = Medium" >> /etc/logwatch/conf/logwatch.conf

    # Set the services to report on to all
    echo "Service = All" >> /etc/logwatch/conf/logwatch.conf

    # Add a cron job for logwatch to run daily
    echo "0 1 * * * /usr/sbin/logwatch" > /etc/cron.d/logwatch


    # Additional hardening steps can be added here as needed
}

# Kali Hardening Basics
function kali_hardening_basics() {
    printf "${col_green}Setting up security basics...${col_reset}\n"
    load_animation

    printf "${col_green}Disabling SSH Root Access...${col_reset}\n"
    line="PermitRootLogin no"
    line2="Protocol 2"
    filename="/etc/ssh/sshd_config"
    echo $line >>$filename
    echo $line2 >>$filename


    printf "${col_green}Restarting SSH Daemon. Should not exist at this point.${col_reset}\n"
    systemctl restart ssh.service

    printf "${col_green}Removing the OpenSSH server package entirely...${col_reset}\n"
    apt remove openssh-server -y

        
    printf "${col_green}Setting up Rkhunter update and cron job...${col_reset}\n"
    rkhunter --update
    cp /etc/rkhunter.conf /etc/rkhunter.conf.local
    filename="/etc/rkhunter.conf.local"
    echo 'MAILON_WARNING="deepmuscle@proton.me"' >>$filename
    echo 'MAIL_CMD=mail' >>$filename

    printf "${col_yellow}Creating cron job script...${col_reset}\n"

cat > rkhuntersh.sh << EOF
#!/bin/bash

# Rkhunter db update
sudo rkhunter --update -y

# Perform a full scan
sudo rkhunter -c --enable all --rwo > /tmp/rkhunter.log

# Send the results
cat /tmp/rkhunter.log | mail -s "Informe de escaneo Rkhunter $(date +%Y-%m-%d)" deepmuscle@proton.me
EOF

    # Make the script executable
    chmod +x rkhuntersh.sh

    # Create the cronjob
    line="0 0 * * * /home/$USER/rkhuntersh.sh"
    touch /etc/cron.d/rkhuntercron
    echo $line >> /etc/cron.d/rkhuntercron
    printf "${col_magenta}"Seccessfully created cronjob for a everyday midnight scan with Rkhunter."${col_reset}\n"

    # Ensuring samhain is installed
    printf "${col_green}Ensuring Samhain...${col_reset}\n"
    wget https://www.la-samhna.de/samhain/samhain-current.tar.gz
    tar -xzvf samhain-current.tar.gz
    cd samhain-*
    ./configure
    make
    make install

    # Creating the cronjob for Samhain
    line="0 0 * * * /usr/local/sbin/samhain -c /usr/local/etc/samhain/samhainrc -t"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    printf "${col_magenta}"Seccessfully created cronjob for a everyday midnight scan with Samhain."${col_reset}\n"

    # Creating the config file
    touch /usr/local/etc/samhain/samhainrc
    echo "log_file = /var/log/samhain.log" >> /usr/local/etc/samhain/samhainrc # /var/log/samhain.log
    echo "log_facility = local0" >> /usr/local/etc/samhain/samhainrc # local0, local1, local2, local3, local4, local5, local6, local7
    echo "log_priority = info" >> /usr/local/etc/samhain/samhainrc # debug, info, notice, warning, err, crit, alert, emerg
    echo "log_verbose = 1" >> /usr/local/etc/samhain/samhainrc # 0 = no verbose, 1 = verbose

     # More security hardening functions
    printf "${col_green}Setting up advanced security hardening...${col_reset}\n"
    load_animation

    # Disable unused filesystems
    printf "${col_green}Disabling unused filesystems...${col_reset}\n"
    echo "install cramfs /bin/true" > /etc/modprobe.d/unused_fs.conf
    echo "install freevxfs /bin/true" >> /etc/modprobe.d/unused_fs.conf
    echo "install jffs2 /bin/true" >> /etc/modprobe.d/unused_fs.conf
    echo "install hfs /bin/true" >> /etc/modprobe.d/unused_fs.conf
    echo "install hfsplus /bin/true" >> /etc/modprobe.d/unused_fs.conf
    echo "install squashfs /bin/true" >> /etc/modprobe.d/unused_fs.conf
    echo "install udf /bin/true" >> /etc/modprobe.d/unused_fs.conf
    echo "install vfat /bin/true" >> /etc/modprobe.d/unused_fs.conf

    # Disable uncommon network protocols
    printf "${col_green}Disabling uncommon network protocols...${col_reset}\n"
    echo "install dccp /bin/true" > /etc/modprobe.d/unused_net.conf
    echo "install sctp /bin/true" >> /etc/modprobe.d/unused_net.conf
    echo "install rds /bin/true" >> /etc/modprobe.d/unused_net.conf
    echo "install tipc /bin/true" >> /etc/modprobe.d/unused_net.conf

    # Restrict core dumps
    printf "${col_green}Restricting core dumps...${col_reset}\n"
    echo "fs.suid_dumpable = 0" > /etc/sysctl.d/50-security-hardening.conf
    echo "kernel.core_uses_pid = 1" >> /etc/sysctl.d/50-security-hardening.conf
    sysctl -p /etc/sysctl.d/50-security-hardening.conf

    # Configure auditd
    printf "${col_green}Configuring auditd...${col_reset}\n"
    apt-get install auditd audispd-plugins -y
    systemctl enable auditd
    systemctl start auditd

    # Additional hardening steps can be added here as needed

}


# Install packages and dependencies
function install_dependencies() {
    # Start spinner
    start_spinner

    # General requirements:
    general_requirements=("git" "nano" "zsh" "open-vm-tools" "open-vm-tools-desktop" "fuse" "powerlevel10k" "rkhunter")

    # You can modify the packages to install at the array above.


    # Iterates on every element in general_requirements array:
    for pkg in "${general_requirements[@]}"; 
        do

        printf "${col_magenta}Checking for $pkg.${col_reset}\n"
        load_animation
        
        if [[ $pkg == "ohmyzsh" ]] || [[ $pkg == "powerlevel10k" ]]; # If the package is ohmyzsh or powerlevel10k
        then
            if [[ $pkg == "ohmyzsh" ]]; then
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
            fi

            if [[ $pkg == "powerlevel10k" ]]; then
                git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
                sed -i '/ZSH_THEME="robbyrussell"/c\ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc
            fi
        fi
        printf "${col_cyan}Setting up $col_magenta$pkg.${col_reset}\n"

        printf "${col_cyan}Uninstalling previous versions of $col_magenta$pkg...${col_reset}\n"

        # Uninstalling previous versions of the package
        apt-get autoremove "$pkg" -y && apt-get --purge autoremove "$pkg" -y

        # Installing the package
        printf "${col_cyan}Installing $col_magenta$pkg...${col_reset}\n"
        load_animation
        apt-get install "$pkg" -y && apt install "$pkg" -y

    done

# Executes Kali Hardening Basics func
    kali_hardening_basics

    printf "${col_green}Basic hardening completed${col_reset}\n"

    load_animation
# Execute Advanced Security Hardening
    advanced_security_hardening 
    # To ensure the highest level of security, regularly update your system, follow security best practices, and review and modify the hardening steps as needed for your specific environment.
	
    printf "${col_green}Advanced security hardening completed${col_reset}\n"

    load_animation

    # Ending spinner and unsetting INSTALLING to null.
    stop_spinner $?

    unset INSTALLING # Unset installing condition for while loop at initial_package_install
    printf "${col_green}Install completed${col_reset}\n"

    printf "${col_green}To ensure the highest level of security, regularly update your system, follow security best practices, and review and modify the hardening steps as needed for your specific environment.${col_reset}\n"

    exit 0
}

## START

# Display init messages
echo $OSTYPE
printf "${col_yellow}\nKali linux - Automated Configuration Script.\n${col_reset}"
printf "${col_yellow}\nThis script will install and configure some basic packages and hardening steps for Kali Linux.\n${col_reset}"
printf "${col_yellow}\nIncludes openvm and fuse configurations for shared folders and powerlevel10k prompt with ohmyzsh. Also cronjobs with rkhunter. Some basic security config included.\n${col_reset}"
printf "${col_magenta}\nVersion: v1.0 rev 1.\n${col_reset}"

function initial_package_install() {
    load_animation
    # Upgrade system packages
    printf "${col_magenta}Do you want to upgrade your system's packages? [Y]es or [N]o${col_reset}\n"

    read ans_1

    case $ans_1 in
        [Yy]*)
            printf "${col_green}Upgrading system packages...${col_reset}\n"
            load_animation

            # Kali Linux repositories
            echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" | sudo tee /etc/apt/sources.list
            echo "deb http://http.kali.org/kali kali-last-snapshot main contrib non-free" | sudo tee /etc/apt/sources.list
            printf "${col_yellow}Installing linux-headers...${col_reset}\n"
            apt-get install -y linux-headers-$(uname -r) # Install linux headers

            apt update -y && apt full-upgrade -y && apt-get update -y # Update and upgrade system packages
            apt-get upgrade -y && apt dist-upgrade -y

            # While loop for installing var
            INSTALLING="1" # Set installing condition for while loop at install_dependencies

            while [[ -n $INSTALLING ]]; 
            do
                start_spinner
                printf "${col_green}Starting install...${col_reset}\n"
                install_dependencies
            done
            ;;
        [Nn]*)
            printf "${col_green}Skipping...${col_reset}\n"
            # While loop for installing var
            INSTALLING="1" # Set installing condition for while loop at install_dependencies

            while [[ -n $INSTALLING ]]; 
            do
                start_spinner
                printf "${col_green}Starting install...${col_reset}\n"
                install_dependencies
            done
            ;;
        *)
            echo "Try again. Options: [Y] for yes. or [N] for no."
            ;;
    esac
}

initial_package_install
