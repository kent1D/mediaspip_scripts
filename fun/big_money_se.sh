#!/bin/bash
#
# big_money_se.sh
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.3.3
#
# Some fun

LOGO="
######################################################################################


 /\$\$      /\$\$                 /\$\$ /\$\$            /\$\$\$\$\$\$  /\$\$\$\$\$\$\$  /\$\$\$\$\$\$ /\$\$\$\$\$\$\$ 
| \$\$\$    /\$\$\$                | \$\$|__/           /\$\$__  \$\$| \$\$__  \$\$|_  \$\$_/| \$\$__  \$\$
| \$\$\$\$  /\$\$\$\$  /\$\$\$\$\$\$   /\$\$\$\$\$\$\$ /\$\$  /\$\$\$\$\$\$ | \$\$  \__/| \$\$  \ \$\$  | \$\$  | \$\$  \ \$\$
| \$\$ \$\$/\$\$ \$\$ /\$\$__  \$\$ /\$\$__  \$\$| \$\$ |____  \$\$|  \$\$\$\$\$\$ | \$\$\$\$\$\$\$/  | \$\$  | \$\$\$\$\$\$\$/
| \$\$  \$\$\$| \$\$| \$\$\$\$\$\$\$\$| \$\$  | \$\$| \$\$  /\$\$\$\$\$\$\$ \____  \$\$| \$\$____/   | \$\$  | \$\$____/ 
| \$\$\  \$ | \$\$| \$\$_____/| \$\$  | \$\$| \$\$ /\$\$__  \$\$ /\$\$  \ \$\$| \$\$        | \$\$  | \$\$      
| \$\$ \/  | \$\$|  \$\$\$\$\$\$\$|  \$\$\$\$\$\$\$| \$\$|  \$\$\$\$\$\$\$|  \$\$\$\$\$\$/| \$\$       /\$\$\$\$\$\$| \$\$      
|__/     |__/ \_______/ \_______/|__/ \_______/ \______/ |__/      |______/|__/      
                                                                                     

VERSION ${VERSION_INSTALL}

######################################################################################
"

# Planter l'appel si on appelle ce script directement
if [ "$0" = *big_money_se.sh ];then
	if [ "$1" = "-f" ]; then
		echo "$LOGO"
	else
		echo "
######################################
MediaSPIP fun
######################################
"
	
		tput setaf 1;
		echo "Ce script ne sert à rien... quoique 
"
		tput sgr0; 
		exit 1
	fi
fi