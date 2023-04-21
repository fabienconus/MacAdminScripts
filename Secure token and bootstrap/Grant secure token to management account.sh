#!/bin/bash
#
# Activate secure token for management account, if needed
#
# By Fabien Conus - 17/01/23


# Arguments passed by JAMF
# Parameter 4: the name of the management account
# Parameter 5: the password for the management account encoded in base 64
secureuser=${4}
b64pass=${5}

# Decode the base 64 encoded password
password="$(echo "$b64pass" | base64 -d)"

# Check if the account provided exists and is admin
check="$("/usr/sbin/dseditgroup" -o checkmember -m $secureuser admin / 2>&1)"
if [[ "$check" =~ "Unable" ]]; then
	echo "The account \"$secureuser\" does not exist on this computer."
	exit 1
elif [[ "$check" =~ "NOT" ]]; then
	echo "The account \"$secureuser\" is not an admin on this computer."
	exit 2
fi

# Check if the provided account already has a secure token
if [[ $("/usr/sbin/sysadminctl" -secureTokenStatus "$secureuser" 2>&1) =~ "ENABLED" ]]; then
	echo "Secure token is already enabled for user \"$secureuser\"."
	exit 0
else
	echo "Secure token is disabled for user \"$secureuser\". Let's activate it."
fi

# Since our only local acount does not have the secute token enabled, let's activate it
output=$(sysadminctl -adminUser "$secureuser" -adminPassword "$password" -secureTokenOn "$secureuser" -password "$password" 2>&1 | grep -c "Error")

# Check if an error occured
if [ $output -eq 0 ]; then
	echo "Token granted !"
else
	echo "Something went wrong. Unable to grant secure token to account $secureuser."
	exit 1
fi

# Verify that the secute token is enabled
securetokencheck="$(/usr/sbin/sysadminctl -secureTokenStatus "$secureuser" 2>&1)"
if [[ "$securetokencheck" =~ "DISABLED" ]]; then
	echo "$securetokencheck"
	echo "Something went wrong."
	exit 3
fi

exit 0