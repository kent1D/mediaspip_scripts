#!/bin/bash
#
# mediaspip_functions
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.3.1
#
# Diverses fonctions permettant d'installer mediaSPIP

export TEXTDOMAINDIR=./locale
export TEXTDOMAIN=mediaspip

VERSION_FUNCTIONS=0.3.1

isNumeric()
{
	echo "$@" | grep -q -v "[^0-9]"
}

in_array(){
    local i
    needle=$1
    shift 1
    # array() undefined
    [ -z "$1" ] && return 1
    for i in $*
    do
	    [ "$i" == "$needle" ] && return 0
    done
    return 1
}

echo_erreur()
{
	tput setaf 1;
	echo $@
	tput sgr0;
}

echo_reussite()
{
	tput setaf 2;
	echo $@
	tput sgr0;
}

#exit function
die ()
{
	echo_erreur $@ 
	echo
	exit 1
}

#error function
error ()
{
	echo_erreur $@
	if [ ! -z "$PID" ];then
		kill "$PID" 2>> $LOG >> $LOG
	fi
	kill "$$" 2>> $LOG >> $LOG	
	exit 1
}

progress_indicator()
{
	#this is a simple progress indicator
	while [ -d /proc/$1 ]; do
		#echo -n "."
		#echo -en "\b-"
		sleep 1
		#echo -en "\b\\"
		#sleep 1
		#echo -en "\b|"
		#sleep 1
		#echo -en "\b/"
		#sleep 1
	done
}

# Function git_log
# Equivalent pour git de svn info
# cf : http://justamemo.com/2009/02/09/git-info-almost-like-svn-info/
git_log()
{
	cd $@
	# Show various information about this git directory
	if [ -d .git ]; then
	  echo "== Remote URL: `git remote -v`"
	
	  echo "== Remote Branches: "
	  git branch -r
	  echo
	
	  echo "== Local Branches:"
	  git branch
	  echo
	
	  echo "== Configuration (.git/config)"
	  cat .git/config
	  echo
	
	  echo "== Most Recent Commit"
	  git --no-pager log --max-count=1
	  echo
	  echo "== Short Revision: `git describe --always`"
	else
	  echo "Not a git repository."
	fi
}

# Planter l'appel si on appelle ce script directement
# On explique que c'est uniquement un fichier de fonctions
if [[ "$0" == *mediaspip_functions.sh ]];then

	echo "
######################################
MediaSPIP functions $VERSION_FUNCTIONS
######################################
	"
	echo "This file is only usefull for its functions
	"
	echo_erreur "This file doesn't work standalone."
	echo
	die  "Please have a look to mediaspip_install.sh"
fi
