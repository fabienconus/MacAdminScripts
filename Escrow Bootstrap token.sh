#!/bin/bash
#
# Escrow the bootstrap token
# using a secute token enabled account
#
# By Fabien Conus - 16/01/2023

# Arguments passed by JAMF
# Parameter 4: the name of the management account
# Parameter 5: the password for the management account encoded in base 64
secureuser=${4}
b64pass=${5}

# Decode the base 64 encoded password
password="$(echo "$b64pass" | base64 -d)"

# Create an expect command to escrow the bootstrap token using the profiles command
echo "*** Escrowing bootstrap token"

command="spawn /usr/bin/profiles install -type bootstraptoken; expect \"Enter the admin user name:\"; send -- \"$secureuser\r\"; expect \"Enter the password for user '$secureuser':\"; send -- \"$password\r\"; expect eof"

# Execute the expect command
expect -c "$command"

# Check if the bootstrap token was correctly escrowed
echo "*** Checking if bootstrap token was correctly escrowed: "

check="$(profiles status -type bootstraptoken | grep "to server" | awk -F":" '{ gsub(/ /,""); print $3}')"

if [[ "$check" == "NO" ]]; then
	echo "*** Failed to escrow bootstrap token"
	echo "$check"
	exit 1
else
	echo "*** Bootstrap token successfully escrowed"
	echo "$check"
fi

exit 0