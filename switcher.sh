#!/bin/bash

sudo -v || { echo "Password cannot be requested."; exit 1; }

current_version=$(php -v | grep -oE 'PHP [0-9]+\.[0-9]+\.?[0-9]*' | head -n1 | cut -d' ' -f2)
if [[ -z "$current_version" ]]; then
	echo "Could not get the current version of PHP. Make sure PHP is installed."
	exit 1
fi

php_versions=(/usr/bin/php*)

while true; do
	clear
	echo "Current PHP version: $current_version"
	echo
	echo "What version do you want to change to?"
	count=0
	selected_version=""
	for version_path in "${php_versions[@]}"; do
		version="${version_path##*/}"
		if [[ "$version" =~ ^php[0-9]+\.[0-9]+\.?[0-9]*$ ]]; then
			((count++))
			echo "$count. $version"
			version_array[$count]=$version
		fi
	done

	printf "Select version (0 to exit): "
	read choice

	if [[ $choice == 0 ]]; then
		exit 0
	fi

	if ((choice >= 1 && choice <= count+1)); then
		if ((choice == count+1)); then
			exit 0
		fi

		selected_version=${version_array[$choice]}
		version_digits=$(echo "$selected_version" | grep -oE '[0-9]+\.[0-9]+\.?[0-9]*')
		read -p "Are you sure about change to version $version_digits? (Y/n): " confirm
		confirm="${confirm:-Y}"

		if [[ $confirm == [yY] ]]; then
			break
		fi
	else
		echo "Invalid selection. Please enter a valid number."
		read -n 1 -s -r -p "Press any key to continue..."
	fi
done

sudo update-alternatives --set php /usr/bin/php"$version_digits"
sudo update-alternatives --set phar /usr/bin/phar"$version_digits"
sudo update-alternatives --set phar.phar /usr/bin/phar.phar"$version_digits"
old_version=$(echo "$current_version" | cut -d '.' -f 1,2)
sudo a2dismod php"$old_version"
sudo a2dismod mpm_event
sudo a2enmod php"$version_digits"
sudo systemctl restart apache2
clear
echo "$(php -v)"
printf "Press any key to continue..."
read tecla
clear