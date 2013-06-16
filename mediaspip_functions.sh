#!/bin/bash
#
# mediaspip_functions
# © 2011-2013 - kent1 (kent1@arscenic.info)
#
# Diverses fonctions permettant d'installer mediaSPIP
#

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
	SOFT="MediaInfo"
	if [ ! -z "$MEDIAINFO" ]; then
		MEDIAINFOVERSION=$(mediainfo --Version |awk '/^MediaInfoLib/ { print $3 }') 2>> $LOG >> $LOG
	fi
	VERSION="$MEDIAINFO_VERSION"
	if [ "$MEDIAINFOVERSION" = "v$VERSION" ]; then
		echo $(eval_gettext 'Info a jour $SOFT $VERSION')
		echo $(eval_gettext 'Info a jour $SOFT $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/$MEDIAINFO_FICHIER ];then
			echo $(eval_gettext 'Info debut $SOFT install $VERSION')
			echo $(eval_gettext 'Info debut $SOFT install $VERSION') 2>> $LOG >> $LOG
			cd $SRC_INSTALL
			wget $MEDIAINFO_URL 2>> $LOG >> $LOG || return 1
			tar -xvjf $MEDIAINFO_FICHIER 2>> $LOG >> $LOG || return 1
		else
			echo $(eval_gettext 'Info debut $SOFT update $VERSION')
			echo $(eval_gettext 'Info debut $SOFT update $VERSION') 2>> $LOG >> $LOG
		fi
		cd "$SRC_INSTALL"/MediaInfo_CLI_GNU_FromSource
		echo $(eval_gettext 'Info $SOFT compil install')
		echo $(eval_gettext 'Info $SOFT compil install') 2>> $LOG >> $LOG
		sh CLI_Compile.sh 2>> $LOG >> $LOG || return 1
		cd MediaInfo/Project/GNU/CLI
		make install 2>> $LOG >> $LOG ||return 1  
		echo $(eval_gettext 'End $SOFT')
	fi
	echo
}

# Installation de mediaspip_munin
# https://github.com/kent1D/mediaspip_munin
mediaspip_munin_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	cd "$SRC_INSTALL"

	if [ ! -z $(which munin-node) ];then
		# Si on a déjà les sources, on ne fait que les mettre à jour
		if [ -d $SRC_INSTALL/mediaspip_munin/.git ]; then
			cd $SRC_INSTALL/mediaspip_munin
			git pull 2>> $LOG >> $LOG || return 1
			NEWREVISION=$(git_log ./ | awk '/^== Short Revision:/ { print $4 }') 2>> $LOG >> $LOG
		# Sinon on les récupère
		else
			git clone https://github.com/kent1D/mediaspip_munin.git 2>> $LOG >> $LOG || return 1
			cd $SRC_INSTALL/mediaspip_munin
			NEWREVISION=$(git_log ./ | awk '/^== Short Revision:/ { print $4 }') 2>> $LOG >> $LOG
		fi

		# On n'active les trucs munin que si :
		# - munin-node est disponible (prouve l'installation de Munin)
		# - SPIP_TYPE est soit ferme soit ferme_full car les scripts sont fait pour monitorer des fermes
		if [ "$SPIP_TYPE" = "ferme" -o "$SPIP_TYPE" = "ferme_full" ]; then
			chmod +x bin/spip_taille_instance.sh 
			if [ ! -h /usr/local/bin/spip_taille_instance.sh ]; then
				ln -s "$SRC_INSTALL"/mediaspip_munin/bin/spip_taille_instance.sh /usr/local/bin 2>> $LOG >> $LOG || return 1
			fi
			if [ ! -h /etc/cron.d/spip_taille_instance ]; then
				ln -s "$SRC_INSTALL"/mediaspip_munin/cron/spip_taille_instance /etc/cron.d 2>> $LOG >> $LOG || return 1
			fi
			if [ ! -h /etc/munin/plugins/spip_mutu_taille ]; then
				ln -s "$SRC_INSTALL"/mediaspip_munin/plugins/spip_mutu_taille /etc/munin/plugins/ 2>> $LOG >> $LOG || return 1
			fi
			if [ ! -h /etc/munin/plugins/spip_mutu_sites ]; then
				ln -s "$SRC_INSTALL"/mediaspip_munin/plugins/spip_mutu_sites /etc/munin/plugins/ 2>> $LOG >> $LOG || return 1
			fi
			if [ ! -h /etc/munin/plugins/mediaspip_media ]; then
				ln -s "$SRC_INSTALL"/mediaspip_munin/plugins/mediaspip_media /etc/munin/plugins/ 2>> $LOG >> $LOG || return 1
			fi
			if [ -z $(grep  "\[mediaspip" /etc/munin/plugin-conf.d/munin-node) ]; then
				echo -e "\n[mediaspip*]\nuser root\n\n" >> /etc/munin/plugin-conf.d/munin-node 2>> $LOG || return 1	
			fi
			if [ -z $(grep "\[spip_mutu" /etc/munin/plugin-conf.d/munin-node) ]; then
				echo -e "\n[spip_mutu*]\nuser root\n\n" >> /etc/munin/plugin-conf.d/munin-node 2>> $LOG || return 1
			fi
			/etc/init.d/munin-node restart 2>> $LOG >> $LOG
		fi
	fi
	echo
}

# Installation de flvtool++
flvtool_plus_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip

	FLVTOOLPLUS=$(which flvtool++)
	SOFT="flvtool++"
	if [ ! -z "$FLVTOOLPLUS" ]; then
		FLVTOOLPLUSVERSION=$(flvtool++ |awk '/^flvtool++/ { print $2 }') 2>> $LOG >> $LOG
	fi

	VERSION="$FLVTOOLPLUS_VERSION"
	if [ "$FLVTOOLPLUSVERSION" = "$VERSION" ]; then
		echo "$(eval_gettext 'Info a jour $SOFT $VERSION')"
		echo "$(eval_gettext 'Info a jour $SOFT $VERSION')" 2>> $LOG >> $LOG
	else
		echo $(eval_gettext 'Info debut $SOFT')
		echo $(eval_gettext 'Info debut $SOFT') 2>> $LOG >> $LOG
		cd $SRC_INSTALL
		if [ ! -d $FLVTOOLPLUS_PATH ];then
			mkdir $FLVTOOLPLUS_PATH 2>> $LOG >> $LOG
		fi
		cd $FLVTOOLPLUS_PATH
		if [ ! -e $FLVTOOLPLUS_FICHIER ];then
			wget $FLVTOOLPLUS_URL 2>> $LOG >> $LOG  || return 1
		fi
		tar xvzf $FLVTOOLPLUS_FICHIER 2>> $LOG >> $LOG
		scons 2>> $LOG >> $LOG
		cp flvtool++ /usr/local/bin
		echo $(eval_gettext 'End $SOFT')
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