#!/bin/bash -e

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

	if [ $(/usr/bin/id -u) -eq 0 ]; then

		echo "This script is being run with root priviledges. This is not a"
		echo "good idea. We will ask you to elevate permissions later, via"
		echo "sudo."
		echo "If you are sure about what this script does and want to"
		echo "proceed, type \"y\"."
		echo "The safe course of action is to type \"n\" and re-run this"
		echo "as a regular user."
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
					echo "Please answer 'y' for yes or 'n' for no."			>&2
					;;
			esac
		done

	else

		echo "Checking your ability get root priviledges via sudo."
		echo "You may be prompted for your password, but we are not actually"
		echo "using elevated priviledges yet. You may need to enter your"
		echo "password again in a few moments."

		if [ $(sudo /usr/bin/id -u) -eq 0 ]; then

			echo "OK"

		else:

			echo "Not running as root, and could not get root via sudo."	>&2
			echo "Perhaps you should re-run this script as root, and elect"	>&2
			echo "to continue when warned about doing so."					>&2
			exit 1

		fi

	fi
}

check_python() {

	echo "Checking Python"

	case "$(python --version 2>&1)" in
		*" 2.7"*)
			echo "OK"
			;;
		*"command not found"*)
			echo "Python not found in your execution path." 				>&2
			echo "Install Python 2.7, or if it is installed, make an alias" >&2
			echo "or symlink so that the bare \`python\` command runs it" 	>&2
			exit 1
			;;
		*)
			echo "Unacceptable Python version." 							>&2
			echo "Install Python 2.7, or if it is installed, make an alias" >&2
			echo "or symlink so that the bare \`python\` command runs" 		>&2
			echo "version 2.7 and not some other version." 					>&2
			exit 1
			;;
	esac

	if ! $(python -c "import w1thermsensor" ); then
		echo "Failed to import Python library 'w1thermsensor'."				>&2
		echo "Run \`pip install w1thermsensor\` or fetch it from"			>&2
		echo "https://github.com/timofurrer/w1thermsensor"					>&2
		exit 1
	fi

}

check_clean_install() {

	echo "Checking for previous installations"

	if test "$(ls -A \"$1\")"; then

		echo "The install directory ($1) is not empty - perhaps this program"
		echo "has been installed once before? If you continue, application"
		echo "files, including the default HTML template and default database,"
		echo "will be overwitten." 

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
					echo "Please answer 'y' for yes or 'n' for no."			>&2
					;;
			esac
		done

		ret=1

	else
		echo "OK"
		ret=0
	fi

	return $ret

}

actually_install() {

	#install_home=$(python -c "import sys; sys.path.append(\"$script_dir\"); import config; print config.install_home;")

	echo "Copying files"

	sudo mkdir -p 	"$install_home/template" 	\
					"$install_home/database"	\
					"$(basedir \"$config\")"	\
					"$(basedir \"$log\")"
	
	sudo cp "$install_script_dir/config.py" "$config_home"
	sudo cp "$install_script_dir/environd.py" "$install_home"
	sudo cp "$install_script_dir/strings.py" "$install_home"
	sudo cp "$install_script_dir/environd.tpl" "$install_home/template/"
	sudo touch "$install_home/database/temperature_readngs.json"
	sudo touch "$log"

	echo -e "Settings permissions on writable files\n"
	echo "What is the name of the user that will be running environd?"
	echo "(if you don't know, the default option is a reasonable guess)"
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
			echo "\"$environd_user\" is not a valid user on this system"	>&2

	done

	echo "Settings permissions for $install_home/database"
	sudo chown -R $environd_user "$install_home/database"
	sudo chmod 750 "$install_home/database"
	sudo chmod 640 "$install_home/database/temperature_readngs.json"

	echo "Setting permissions for $log"
	sudo chown $environd_user "$log"
	sudo chmod 640 "$log"

	echo "How often should we record a temperature reading? (default is 15)"
	echo "(One reading takes up about 70 bytes in the database, so we can"
	echo "store LOTS of data, even on a modext SD card)"

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
					echo "Interval must be a whole number."					>&2
				;;
		esac
	done

	echo "Installing cronjob for user $environd_user"

	cat <(sudo crontab -l -u $environd_user)								\
		<(echo "*/$read_interval 0 0 0 0 \"$install_home/environd.py\"")	\
		| sudo crontab -u $environd_user -

}

install_environd() {

	check_permissions
	get_install_config
	check_python
	check_clean_install
	actually_install

	# instruct user to install hardware sensor, install web server, and update www_out in config if needed

	echo "Scripted install is complete!"
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""

}


install_environd