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

# Colors 
# USAGE: echo -e "$COL_YELLOW\nLOREM IPSUM TEXTO\n$COL_RESET"
# Reset
	COL_RESET='\033[0m'       # Text Reset/
	Black='\033[0;30m'        # Black
	COL_RED='\033[0;31m'      # Red
	COL_GREEN="\033[1;32m"    # Green
	COL_YELLOW="\033[1;33m"   # Yellow
	COL_MAGENTA="\033[1;35m"  # Purple - Magenta
	COL_CYAN='\033[0;36m'     # Cyan
	COL_BACKG_CYAN='\033[46m' # Cyan Background


# Ensure root
if [[ $(id -u) -ne 0 ]] ;
	then
		echo "Please run as root." ;
	exit 1 ;
fi

# PWD to working directory string
W_DIR=$(pwd)

function load_1()
{
	echo -ne '⋮ \r'
	sleep 0.3
	echo -ne '⋮ ⋰ ⋯ ⋱ \r'
	sleep 0.3
	echo -ne '⋮ ⋰ ⋯ ⋱ ⋮ \r'
	sleep 0.5
	echo -ne '⋮ ⋰ ⋯ ⋱ ⋮ ✓\r'
	echo -ne '\n'
}

function _spinner()
{
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
            echo -ne ${2}
            printf "%${column}s"

            # start spinner
            i=1
            sp='\|/-'
            delay=${SPINNER_DELAY:-0.15}

            while :
            do
                printf "\b${sp:i++%${#sp}:1}"
                sleep $delay
            done
            ;;
        stop)
            if [[ -z ${3} ]]; then
                echo "spinner is not running.."
                exit 1
            fi

            kill $3 > /dev/null 2>&1

            # inform the user uppon success or failure
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

function start_spinner()
{
    # $1 : msg to display
    _spinner "start" "${1}" &
    # set global spinner pid
    _sp_pid=$!
    disown
}

function stop_spinner()
{
    # $1 : command exit status
    _spinner "stop" $1 $_sp_pid
    unset _sp_pid
}

function KaliHardeningBasics()
{

        echo -e $COL_GREEN "Setting up security basics..." $COL_RESET
        load_1

        echo -e $COL_GREEN "Disabling SSH Root Access..." $COL_RESET
            line="PermitRootLogin	no"
            line2="Protocol	2"
            filename="/etc/ssh/sshd_config"
            echo $line >> $filename
            echo $line2 >> $filename

        echo -e $COL_GREEN "Restarting SSH Deamon. Should not exist at this point." $COL_RESET
            systemctl restart ssh.service

        echo -e $COL_GREEN "Removing the OpenSSH server package entirely..." $COL_RESET
            apt remove openssh-server -y
        
        echo -e $COL_GREEN "Setting up Rkhunter update and cronjob..." $COL_RESET
        rkhunter --update
        cp /etc/rkhunter.conf /etc/rkhunter.conf.local
        filename="/etc/rkhunter.conf.local"
        echo 'MAILON_WARNING="deepmuscle@proton.me"' >> $filename
        echo 'MAIL_CMD=mail' >> $filename
        
        echo -e $COL_YELLOW "Creating cronjob script..." $COL_RESET

cat > rkhuntersh.sh << EOF
#!/bin/bash

# Actualizar la base de datos de Rkhunter
sudo rkhunter --update -y

# Ejecutar un escaneo completo
sudo rkhunter -c --enable all --rwo > /tmp/rkhunter.log

# Enviar el informe por correo
cat /tmp/rkhunter.log | mail -s "Informe de escaneo Rkhunter $(date +%Y-%m-%d)" deepmuscle@proton.me
EOF

        chmod +x rkhuntersh.sh

        line="0 0 * * * /home/$USER/rkhuntersh.sh"
        touch /etc/cron.d/rkhuntercron
        echo $line >> /etc/cron.d/rkhuntercron

        echo -e $COL_MAGENTA "Seccessfully created cronjob for a everyday midnight scan." $COL_RESET

        echo -e $COL_GREEN "Setting up Samhain..." $COL_RESET
        wget https://www.la-samhna.de/samhain/samhain-current.tar.gz
        tar -xzvf samhain-current.tar.gz
        cd samhain-*
        ./configure
        make
        make install

        # Creating the cronjob
        line="0 0 * * * /usr/local/sbin/samhain -c /usr/local/etc/samhain/samhainrc -t"
        (crontab -u root -l; echo "$line" ) | crontab -u root -
       
        echo -e $COL_MAGENTA "Seccessfully created cronjob for a everyday midnight scan with Samhain." $COL_RESET


}


function install_p2()
{

    #Start spinner
    start_spinner

    # General requirements:
	g_requirements=( "git" "nano" "zsh" "ohmyzsh" "open-vm-tools-desktop" "fuse" "powerlevel10k" "rkhunter" )

	# Iterates on every element at g_requirements array:
	for pkg in "${g_requirements[@]}" ;
		do
            echo -e $COL_MAGENTA "Checking for "$pkg"." $COL_RESET
			load_1

            if [[ $pkg == "ohmyzsh" ]] || [[ $pkg == "powerlevel10k" ]]
            then
                if [[ $pkg == "ohmyzsh" ]] ;
				then
                    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
				fi

				if [[ $pkg == "powerlevel10k" ]] ;
				then
                    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
                    sed -i '/ZSH_THEME="robbyrussell"/c\ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc
				fi
            fi


			echo -e $COL_CYAN "Setting up $COL_MAGENTA"$pkg"." $COL_RESET
			echo -e $COL_CYAN "Uninstalling previous versions of $COL_MAGENTA"$pkg"..." $COL_RESET

			apt-get autoremove "$pkg" -y && apt-get --purge autoremove "$pkg" -y

			echo -e $COL_CYAN "Installing $COL_MAGENTA"$pkg"..." $COL_RESET
			load_1

			apt-get install "$pkg" -y && apt install "$pkg" -y

	done
 
# Executes Kali Hardening Basics func
    KaliHardeningBasics

	load_1

	# Ending spinner and unseting INSTALLING to null.
		stop_spinner $?

		unset INSTALLING # Unset installing condition for while loop at install_p1
	    echo -e $COL_GREEN "Install completed" $COL_RESET
	exit 0

}


## START

# Display init messages
	echo $OSTYPE
	echo -e "$COL_YELLOW\nKali linux - Auto Installer for a first fresh install.\n$COL_RESET"
    echo -e "$COL_YELLOW\nIncludes openvm and fuse configurations for shared folders and powerlevel10k prompt with ohmyzsh. Also cronjobs with rkhunter. Some basic security config included.\n$COL_RESET"
    echo -e "$COL_MAGENTA\nVersion: v1.0 rev 0.\n$COL_RESET"

function install_p1()
{
	load_1
	# Upgrade system packages
		echo -e $COL_MAGENTA "Do you want to upgrade your system's packages? [Y]es or [N]o" $COL_RESET
		
			read ans_1
		
	case $ans_1 in
			[Yy]* ) echo -e $COL_GREEN "Upgrading system packages..." $COL_RESET
			load_1

            echo -e $COL_MAGENTA "Enabling the kali-rolling branch..." $COL_RESET
            echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" | sudo tee /etc/apt/sources.list
			
            echo -e $COL_MAGENTA "Enabling the kali-last-snapshot branch..." $COL_RESET
            echo "deb http://http.kali.org/kali kali-last-snapshot main contrib non-free" | sudo tee /etc/apt/sources.list

            echo -e $COL_YELLOW "Installing linux-headers..." $COL_RESET
            apt-get install -y linux-headers-$(uname -r)


            apt update -y && apt full-upgrade -y && apt-get update -y

            apt-get upgrade -y && apt dist-upgrade -y

                #While loop for installing var
                INSTALLING="1"

	            while [[ -n $INSTALLING ]] ;
	            	do
	            		start_spinner
	            		echo -e $COL_GREEN "Starting install..." $COL_RESET
	            		install_p2
	            	done
		;;
			[Nn]* )  echo -e $COL_GREEN "Skipping..." $COL_RESET
			load_1
		;;
			*) echo "Try again. Options: [Y] for yes. or [N] for no."
		;;
	esac
}

install_p1

