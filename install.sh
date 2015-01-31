#!/bin/bash -e

#
# Installs RPI Environd in a Debian-like environment
#

get_install_config() {

	# These values are used for the install ONLY and do not alter the config.
	# That means that if you change something here before running this script,
	# you MUST also update config.py and environd.py

	install_home="/opt/environd"
	config_home="/etc/environd"
	log="/var/log/environd.log"

	# Don't change this

	install_script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

}

check_permissions() {

	#
	# Make sure that we either are, or can get, root.
	# Encourage the user to not run the whole thing as root.
	# The logic here (trying to save the user from themselves) will break
	# functionaliy if run as root in an environment where root can't sudo.
	#

	if [ $(/usr/bin/id -u) -eq 0 ]; then

		echo "This script is being run with root priviledges. This is not a good idea. We will ask you to elevate permissions later, via sudo."
		echo "If you are sure about what this script does and want to proceed, type \"y\". The safe course of action is to type \"n\" and re-run this as a regular user."
		echo ""

		while true; do
			read -p "Continue with excessive priviledge? [y/n]: " ans
			case $ans in
				[Yy]* )
					echo "OK"
					break
					;;
				[Nn]* ) 
					echo "Aborting."
					exit 0
					;;
				* ) 
					echo "Please answer 'y' for yes or 'n' for no." >&2
					;;
			esac
		done

	else

		echo "Checking your ability get root priviledges via sudo."
		echo "You may be prompted for your password, but we are not actually using elevated priviledges yet. You may need to enter your password again in a few moments."

		if [ "$(sudo /usr/bin/id -u)" == "0" ]; then
			echo "OK"
		else

			echo "Not running as root, and could not get root via sudo. Perhaps you will need to re-run this script as root, and elect to continue when warned about doing so." >&2
			exit 1

		fi

	fi
}

check_python() {

	#
	# Check that the `python` command launches Python vervion 2.7, 
	# and check that we can import w1thermsensor. Offer to install
	# it via pip if not.
	#

	echo "Checking Python"

	case "$(python --version 2>&1)" in
		*" 2.7"*)
			echo "OK"
			;;
		*"command not found"*)
			echo "Python not found in your execution path." >&2
			echo "Install Python 2.7, or if it is installed, make an alias or symlink so that the bare \`python\` command runs it" 2
			exit 1
			;;
		*)
			echo "Unacceptable Python version." >&2
			echo "Install Python 2.7, or if it is installed, make an alias or symlink so that the bare \`python\` command runs version 2.7 and not some other version." >&2
			exit 1
			;;
	esac

	if ! $(python -c "import w1thermsensor" 2> /dev/null); then

		echo "Failed to import Python library 'w1thermsensor'." >&2

		if ! $(pip --version 2>&1 > /dev/null); then

			echo "Additionally, pip not found. To install w1thermsensor package, install (python-)pip and run \`pip install w1thermsensor\`, or download and install it manually per https://github.com/timofurrer/w1thermsensor" >&2

			exit 1

		else

			while true; do
				read -p "Install w1thermsensor via PIP? [y/n]: " ans
				case $ans in
					[Yy]* )
						sudo pip install w1thermsensor
						break
						;;
					[Nn]* ) 
						echo "Python withermsensor package required. See https://github.com/timofurrer/w1thermsensor." >&2
						echo "Exiting."
						exit 0
						;;
					* ) 
						echo "Please answer 'y' for yes or 'n' for no." >&2
						;;
				esac
			done

		fi

	fi

}

check_clean_install() {

	#
	# Warn the user if they risk overwriting something
	#

	echo "Checking for previous installations"

	if test "$(ls -A "$install_home" 2> /dev/null)"; then

		echo "The install directory ($install_home) is not empty."
		echo "Perhaps this program has been installed once before? If you continue, application files, including the default HTML template and default database, will be overwitten." 

		while true; do
			read -p "Continue to overwrite files? [y/n]: " ans
			case $ans in
				[Yy]* )
					echo "OK"
					break
					;;
				[Nn]* ) 
					echo "Aborting."
					exit 0
					;;
				* ) 
					echo "Please answer 'y' for yes or 'n' for no." >&2
					;;
			esac
		done

	else
		echo "OK"
	fi

}

actually_install() {

	#
	# Copy files, set permissions, & install cronjob
	#

	#install_home=$(python -c "import sys; sys.path.append(\"$script_dir\"); import config; print config.install_home;")

	echo "Copying files"

	sudo mkdir -p "$install_home/template" 	\
		"$install_home/database"	\
		"$(dirname "$config_home/.")"	\
		"$(dirname "$log")"
	
	sudo cp "$install_script_dir/config.py" "$config_home"
	sudo cp "$install_script_dir/environd.py" "$install_home"
	sudo cp "$install_script_dir/strings.py" "$install_home"
	sudo cp "$install_script_dir/environd.tpl" "$install_home/template/"
	sudo touch "$install_home/database/temperature_readngs.json"
	sudo touch "$log"

	echo -e "\nSettings permissions on writable files\n"
	echo "What is the name of the user that will be running environd?"
	echo -e "(if you don't know, the default option is a reasonable guess)\n"
	while true; do

		read -p "User Name [enter for $(whoami)]:" ans
		case $ans in
			"" )
				environd_user=$(whoami)
				;;
			* ) 
				environd_user=$ans
				;;
		esac

		# confirm that we were given a valid username
		if id -u $environd_user >/dev/null 2>&1; then
			echo "OK"
			break
		else
			echo "\"$environd_user\" is not a valid user on this system" >&2
		fi

	done

	echo "Settings permissions for $install_home/database"

	sudo chown -R $environd_user:nogroup "$install_home/database"
	sudo chmod 750 "$install_home/database"
	sudo chmod 640 "$install_home/database/temperature_readngs.json"

	echo "Setting permissions for $log"
	sudo chown $environd_user:nogroup "$log"
	sudo chmod 640 "$log"

	echo -e "\nHow often should we record a temperature reading? (default is 15)"
	echo "(One reading takes up about 70 bytes in the database, so we can"
	echo -e "store LOTS of data, even on a modest SD card)\n"

	while true; do
		read -p "Enter interval in minutes [15]:" ans
		case $ans in
			"" )
				read_interval=15
				break
				;;
			* ) 
				if [[ $ans =~ ^-?[0-9]+$ ]]; then
					read_interval=$ans
					break
				else
					echo "Interval must be a whole number." >&2
				fi
				;;
		esac
	done

	# Check for an existing cronjob before installing one
	# This would go better under check_cleck_install() but sharing data
	# between bash functions is clumsy and I am lazy.

	if test "$(crontab -l -u $environd_user | grep environd)"; then

		echo "Looks like there is already a cronjob for environd. Skipping job install. To change the read interval, edit this cronjob manually."

	else

		echo "Installing cronjob for user $environd_user"

		cat <(sudo crontab -l -u $environd_user)	\
			<(echo "*/$read_interval * * * * \"$install_home/environd.py\"")\
			| sudo crontab -u $environd_user - > /dev/null
	fi

}

print_end_info() {

	#
	# instruct user to install hardware sensor, install web server, and update www_out in config if needed
	#

	echo "Scripted install is complete!"
	echo ""
	echo "You must take the following additional actions:"
	echo ""	
	echo "  1. Connect the DS18B20 to 3.3v, 5v, and GPIO #4"
	# this looks terrible and is probably not helpful but I like it so deal.
	echo "
	             ----(ground)------+
	            /                  | 
	        +--D  <-DS18B20        |
	        |   \            +--+  |
	        |    ----(3.3v)--|oo|  |
	        |                |oo|  |
	        |                |oo|--+
	        +-----(GPIO #4)--|oo|   
	                         |oo|   
	                        --//--  
	                        -|oo|   
	     notch/clip side -> []oo|   
	                        -|oo|   
	                        --//--  
	     "
	echo "     This tutorial has *much* better drawings: https://learn.adafruit.com/adafruits-raspberry-pi-lesson-11-ds18b20-temperature-sensing/hardware"
	echo ""
	echo "  2. Install an HTTP server like lighttpd, NGINX, or Monkey."
	echo ""
	echo "  3. Open the Environd config file ($config_home)/config.py and make sure that the www_out file is somewhere under the document root of the web server, and that the user running environd can write to it."
	echo ""
	echo "End."
	echo ""

}

install_environd() {

	check_permissions
	get_install_config
	check_python
	check_clean_install
	actually_install
	print_end_info

}


install_environd

