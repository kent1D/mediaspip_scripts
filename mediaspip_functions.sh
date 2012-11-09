#!/bin/bash
#
# mediaspip_functions
# © 2011-2012 - kent1 (kent1@arscenic.info)
# Version 0.3.4
#
# Diverses fonctions permettant d'installer mediaSPIP
#
# Mises à jour
# Version 0.3.4 - Ajout d'un sleep sur la vérification de la connexion internet

export TEXTDOMAINDIR=./locale
export TEXTDOMAIN=mediaspip

VERSION_FUNCTIONS=0.3.4

isNumeric()
{
	printf "$@" | grep -q -v "[^0-9]"
}

in_array()
{
    local i
    needle=$1
    shift 1
    # array() undefined
    [ -z "$1" ] && return 1
    for i in $*
    do
	    [ "$i" = "$needle" ] && return 0
    done
    return 1
}

# Fonction d'affichage des erreurs
# Affiche les erreurs en rouge
echo_erreur()
{
	tput setaf 1;
	printf "$@"
	printf "\n"
	tput sgr0;
}

echo_reussite()
{
	tput setaf 2;
	printf "$@"
	printf "\n"
	tput sgr0;
}

#exit function
die ()
{
	echo_erreur "$@"
	printf "\n"
	exit 1
}

#error function
error ()
{
	echo_erreur "$@"
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
	  printf "== Remote URL: `git remote -v`"
	
	  printf "== Remote Branches: "
	  git branch -r
	  printf "\n"
	
	  printf "== Local Branches:"
	  git branch
	  printf "\n"
	
	  printf "== Configuration (.git/config)"
	  cat .git/config
	  printf "\n"
	
	  printf "== Most Recent Commit"
	  git --no-pager log --max-count=1
	  printf "\n"
	  printf "== Short Revision: `git describe --always`"
	else
	  printf "Not a git repository."
	fi
}

verif_internet_connexion()
{
	wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null
	sleep 1
	if [ ! -s /tmp/index.google ];then
		rm /tmp/index.google
		return 1
	fi
	rm /tmp/index.google
}

verif_svn_protocole()
{
	# On vérifie que l'on a bien accès au protocole svn://
	svn info svn://trac.rezo.net/spip/branches/spip-2.1 2>> /dev/null >> /dev/null
	if [ $? != "0" ]; then
		echo_erreur $(eval_gettext "Erreur script protocole svn") 1>&2
		exit 1
	fi
}

# Installation de mediainfo
# http://mediainfo.sourceforge.net/fr
media_info_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	MEDIAINFO=$(which mediainfo)
	if [ ! -z "$MEDIAINFO" ]; then
		MEDIAINFOVERSION=$(mediainfo --Version |awk '/^MediaInfoLib/ { print $3 }') 2>> $LOG >> $LOG
	fi
	VERSION="0.7.61"
	if [ "$MEDIAINFOVERSION" = "v$VERSION" ]; then
		echo $(eval_gettext 'Info a jour mediainfo $VERSION')
		echo $(eval_gettext 'Info a jour mediainfo $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/MediaInfo_CLI_0.7.61_GNU_FromSource.tar.bz2 ];then
			echo $(eval_gettext 'Info debut mediainfo install $VERSION')
			echo $(eval_gettext 'Info debut mediainfo install $VERSION') 2>> $LOG >> $LOG
			cd $SRC_INSTALL
			wget http://downloads.sourceforge.net/mediainfo/MediaInfo_CLI_0.7.61_GNU_FromSource.tar.bz2 2>> $LOG >> $LOG || return 1
			tar -xvjf MediaInfo_CLI_0.7.61_GNU_FromSource.tar.bz2 2>> $LOG >> $LOG || return 1
		else
			echo $(eval_gettext 'Info debut mediainfo update $VERSION')
			echo $(eval_gettext 'Info debut mediainfo update $VERSION') 2>> $LOG >> $LOG
		fi
		cd "$SRC_INSTALL"/MediaInfo_CLI_GNU_FromSource
		echo $(eval_gettext 'Info mediainfo compil install')
		echo $(eval_gettext 'Info mediainfo compil install') 2>> $LOG >> $LOG
		sh CLI_Compile.sh 2>> $LOG >> $LOG || return 1
		cd MediaInfo/Project/GNU/CLI
		make install 2>> $LOG >> $LOG ||return 1  
		echo $(eval_gettext "End mediainfo")
	fi
	echo
}
# Planter l'appel si on appelle ce script directement
# On explique que c'est uniquement un fichier de fonctions
if [ "$0" = *mediaspip_functions.sh ]; then
printf "\n
######################################
MediaSPIP functions $VERSION_FUNCTIONS
######################################\n"
printf "This file is only usefull for its functions\n"
echo_erreur "This file doesn't work standalone."
printf "\n"
die "Please have a look to mediaspip_install.sh"
fi