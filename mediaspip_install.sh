#!/bin/bash
#
# mediaspip_install.sh
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.3.8
# 
# Ce script installe toutes les dépendances logicielles nécessaires au bon fonctionnement de mediaSPIP :
# - php5-gd2
# - php5-curl
# - php5-imagick
# - libx264
# - lame
# - libopencore-amr
# - libtheora
# - rtmpdump
# - flvtool2
# - mediainfo
# - ffmpeg
# - ffmpeg2theora
#
# Ce script installe également SPIP et l'ensemble des extensions et plugins nécessaires à MediaSPIP
#
# Mises à jour :
# Version 0.3.2 - Meilleure détection des distribs avec lsb_release
# Version 0.3.3 - On fait marcher le script avec dash
# Version 0.3.4 - Installation de l'écran de sécurité dans mediaspip_spip_installation.sh
# Version 0.3.5 - Mise à jour de libvpx en 0.9.7-p1 "Cayuga"
# Version 0.3.6 - Mise à jour de MediaInfo en 
# Version 0.3.7 - Installation de flvtool++ en version 1.2.1
# Version 0.3.8 - Mise à jour de ffmpeg2theora en version 0.28

# On pose une variable sur le répertoire courant permettant de savoir 
# d'où le script est lancé
CURRENT=$(pwd)

LOG=/dev/null

export TEXTDOMAINDIR=$CURRENT/locale
export TEXTDOMAIN=mediaspip

I18NLIB=$(which gettext.sh)

# source in I18N library - shown above
if [ -f "$I18NLIB" ]; then
	. "$I18NLIB"
else
	printf "ERROR - $I18NLIB NOT FOUND"
	printf "Please install the gettext package via the command:"
	printf "apt-get -y install gettext gettext-base"
	exit 1
fi

VERSION_INSTALL="0.3.8"

LOGO="
######################################################################################


.___  ___.  _______  _______   __       ___           _______..______    __  .______   
|   \/   | |   ____||       \ |  |     /   \         /       ||   _  \  |  | |   _  \  
|  \  /  | |  |__   |  .--.  ||  |    /  ^  \       |   (----\`|  |_)  | |  | |  |_)  | 
|  |\/|  | |   __|  |  |  |  ||  |   /  /_\  \       \   \    |   ___/  |  | |   ___/  
|  |  |  | |  |____ |  '--'  ||  |  /  _____  \  .----)   |   |  |      |  | |  |      
|__|  |__| |_______||_______/ |__| /__/     \__\ |_______/    | _|      |__| | _|     

VERSION ${VERSION_INSTALL}

######################################################################################
"

# Inclusion d'un logo aléatoire ;)
if [ -d "fun" ];then
	DIR="./fun/*.sh"
	RANDOMFILE=$(ls $DIR | shuf -n1)
	. $RANDOMFILE
fi

# On affiche le logo ... en vert
tput setaf 2;
printf "$LOGO"
tput sgr0;

# On inclut le fichier de fonctions
FICHIER='mediaspip_functions.sh'
. ./mediaspip_functions.sh || (tput setaf 1;printf "$(eval_gettext 'Erreur fichier $FICHIER')";tput sgr0;kill "$$";exit 1)

# On inclut le fichier d'installation de SPIP et de MediaSPIP
FICHIER='mediaspip_spip_installation.sh'
. ./mediaspip_spip_installation.sh || error "$(eval_gettext 'Erreur fichier $FICHIER')"

#########################################
# Vérifications de base :
# - doit être lancé par root
# - doit être sur une distribution que l'on connait 
#

if [ "$(id -u)" != "0" ]; then
	echo_erreur "$(eval_gettext 'Erreur script root')" 1>&2
	exit 1
fi

LSB_RELEASE=$(which lsb_release)

if [ "$LSB_RELEASE" ] && [ -x $LSB_RELEASE ]; then
	DISTRIB=$($LSB_RELEASE -si | tr [:upper:] [:lower:])
	DISTRO=$($LSB_RELEASE -sc | tr [:upper:] [:lower:])
# Cas d'Ubuntu
elif [ -r /etc/lsb-release ];then
	DISTRIB=$(cat /etc/lsb-release | grep ID | cut -c 12- | tr '[A-Z]' '[a-z]')
	DISTRO=$(cat /etc/lsb-release | grep CODE | cut -c 18- | tr '[A-Z]' '[a-z]')
# Cas de debian
elif [ -r /etc/debian_version ]; then
	DISTRIB="debian"
	NUMBER=$(cat /etc/debian_version | cut -c 1)
	if [ "$NUMBER" = '6' ]; then
		DISTRO="squeeze"
	else
		DISTRO="lenny"
	fi
# Cas de redhat (?) et centos
elif [ -r /etc/redhat-release ]; then
	DISTRIB=$(cat /etc/redhat-release |awk  '{ print $1 }' | tr '[A-Z]' '[a-z]' | tr '[:punct:]' '_')
	DISTRO=$(cat /etc/redhat-release |awk  '{ print $3 }' | tr '[A-Z]' '[a-z]' | tr '[:punct:]' '_')
else
	echo_erreur "$(eval_gettext 'Erreur script distro inconnue')"
	exit 1
fi

OKDISTRO='lenny squeeze lucid 5_3';
case "$OKDISTRO" in 
	*$DISTRO*);;
	*)
		die "$(eval_gettext 'Erreur script distro non suportee $DISTRIB $DISTRO')"
		shift
		;;
esac

# On vérifie que l'on a bien accès au programme pkg-config 
# Il permet de connaitre les versions des librairies sur le système
PKG_CONFIG=$(which pkg-config)

if [ ! -x $PKG_CONFIG ]; then
	echo_erreur "$(eval_gettext 'Erreur script pkg-config')" 1>&2
	exit 1
fi

#########################################
# Variables éditables pour l'utilisateur
#

# Où sont téléchargées les sources
SRC_INSTALL="/usr/local/src"

# location of log file
LOG="/var/log/mediaspip_install.log"

# On récupère le nombre de cores de la machine pour les utiliser lors des compilations
NO_OF_CPUCORES=`grep -c ^processor /proc/cpuinfo 2>/dev/null`
if [ ! "$?" = "0" ]
then
    NO_OF_CPUCORES=2
fi

# Le upload_max_filesize de php
PHP_UPLOAD_SIZE="150M"

# Type d'installation des dépendances 
# valeurs : stable|dev
DEP_VERSION="stable"

# Emplacement final de SPIP et MediaSPIP
SPIP="/var/www/mediaspip"

# Version de SPIP (svn ou stable)
SPIP_VERSION="svn"
SPIP_TYPE="ferme_full"
SPIP_SVN="svn://trac.rezo.net/spip/branches/spip-2.1"

if [ "$DISTRIB" = "centos" ];then
	SPIP_USER="apache"
	SPIP_GROUP="apache"
else
	SPIP_USER="www-data"
	SPIP_GROUP="www-data"
fi

# On insère un fichier de modification de ces variables si présent
if [ -r /etc/default/mediaspip ]; then
	. /etc/default/mediaspip
fi

while [ $# -gt 0 ]; do
	case $1 in
		--help|-h) HELP=$(eval_gettext "Help message")
		VERSION_AFFICHER=$(eval_gettext 'Info mediaspip installation $VERSION_INSTALL')
		echo "$VERSION_AFFICHER"
		echo "$HELP"
		exit 0;;
		--version|-v) VERSION_AFFICHER=$(eval_gettext 'Info mediaspip installation $VERSION_INSTALL')
		echo "$VERSION_AFFICHER"  
		exit 0;;
		--lang|-lang) 
			case "${2}" in
				en) export LANG="en_US.UTF-8"
				shift 2;;
				fr) export LANG="fr_FR.UTF-8"
				shift 2;;
				"") echo_erreur "$(eval_gettext 'Erreur langue non set')"
				ERROR=oui
				shift 2;;
				*) echo_erreur "$(eval_gettext 'Erreur langue inexistante')"
				ERROR=oui
				shift;;
			esac
		shift;;
		--allways-yes|-y) NO_QUESTION="yes"
		echo $(eval_gettext 'Info options no_question')
		shift;;
		--src_install|-src) SRC_INSTALL="${2}"
		shift 2;;
		--log|-l) LOG="${2}"
		shift 2;;
		--cpus|-c)
			if [ ! -z "${2}" ];then
				if(isNumeric "${2}");then
					if ((${2} > $NO_OF_CPUCORES));then
						CPU_NB=${2}
						echo_erreur "$(eval_gettext 'Erreur option cpus trop $CPU_NB')"
						ERROR=oui
					else 
						NO_OF_CPUCORES="${2}"
					fi
				else
					echo_erreur "$(eval_gettext 'Erreur option cpus numerique')"
					ERROR="oui"
				fi
			else
				echo_erreur "$(eval_gettext 'Erreur option cpus numerique')"
				ERROR="oui"
			fi
		shift 2;;
		--dep-version) DEP_VERSION="${2}"
		shift 2;;
		--disable-alternc) DISABLE_ALTERNC="yes"
		echo $(eval_gettext 'Info options disable_alternc')
		shift;;
		--disable-apache) DISABLE_APACHE="yes"
		echo $(eval_gettext 'Info options disable_apache')
		shift;;
		--disable-ffmpeg) DISABLE_FFMPEG="yes"
		echo $(eval_gettext 'Info options disable_ffmpeg')
		shift;;
		--disable-mediaspip) DISABLE_MEDIASPIP="yes"
		echo $(eval_gettext 'Info options disable_mediaspip')
		shift;;
		--spip|-s) SPIP="${2}"
		shift 2;;
		--spip_version|-s_v) SPIP_VERSION="${2}"
		shift 2;;
		--spip_svn|-s_svn) SPIP_SVN="${2}"
		shift 2;;
		--spip_user) SPIP_USER="${2}"
		shift 2;;
		--spip_group) SPIP_GROUP="${2}"
		shift 2;;
		--spip_type)
			case "${2}" in
				ferme_full|ferme|minimal|full|none) SPIP_TYPE=${2}
				shift 2;;
				*)
				TYPEDEMANDE=${2}
				echo_erreur "$(eval_gettext 'Erreur mediaspip type disponible $TYPEDEMANDE')"
				ERROR=oui
				shift;;
			esac
		shift 2;;
	esac
done

verif_internet_connexion || error "$(eval_gettext 'Erreur internet connexion')"

if [ "$ERROR" = "oui" ]; then
	exit 1
fi


FICHIER="distribs/$DISTRIB_$DISTRO_common.sh"
. ./distribs/"$DISTRIB"_"$DISTRO"_common.sh	2>> $LOG >> $LOG || error "$(eval_gettext 'Erreur fichier $FICHIER')"

if [ "$DEP_VERSION" = "stable" ]; then
	FICHIER="distribs/$DISTRIB_$DISTRO_stable.sh"
	. ./distribs/"$DISTRIB"_"$DISTRO"_stable.sh	2>> $LOG >> $LOG || error "$(eval_gettext 'Erreur fichier $FICHIER')"
else
	FICHIER="distribs/$DISTRIB_$DISTRO_dev.sh"
	. ./distribs/"$DISTRIB"_"$DISTRO"_dev.sh 2>> $LOG >> $LOG || error "$(eval_gettext 'Erreur fichier $FICHIER')"
fi

LANGUES_COMPAT='en fr'
LANGUE=$(expr substr $LANG 1 2)
case $LANGUE in
	en|fr) ;;
	*)
	export LANG="en_US.UTF-8";;
esac 

###############################
# Suite des fonctions du script
###############################

QUESTION_VALID=$(eval_gettext "Question valider")

echo $(eval_gettext 'Info distro version $DISTRIB $DISTRO') 1>&2
echo

# Quelques questions préalables.
# Il est possible de les passer en ajoutant "-y" ou "--allways-yes" en option au script 
if [ "$NO_QUESTION" != "yes" ]; then
	# Demande de valider l'emplacement des fichiers source des binaires
	# Trois reponses valides possibles :
	# - y
	# - o
	# - return (vide)
	eval_gettext "Info source installation"
	echo " $SRC_INSTALL"
	echo -n "$QUESTION_VALID"
	read REPLY
	[ "$REPLY" = "y" ] || [ "$REPLY" = "o" ] || [ -z "$REPLY" ] || die $(eval_gettext "Erreur valide SRC_INSTALL")
	echo
	
	# Demande de valider l'emplacement des fichiers de log
	# Trois reponses valides possibles :
	# - y
	# - o
	# - return (vide)
	eval_gettext "Info log installation"
	#echo ""
	echo " $LOG"
	echo -n "$QUESTION_VALID"
	read REPLY
	[ "$REPLY" = "y" ] || [ "$REPLY" = "o" ] || [ -z "$REPLY" ] || die $(eval_gettext "Erreur valide LOG")
	echo
	
	# Demande de valider l'emplacement des fichiers de SPIP et MediaSPIP
	# Trois reponses valides possibles :
	# - y
	# - o
	# - return (vide)
	if [ "$SPIP_TYPE" != "none" ];then
		eval_gettext "Info SPIP installation"
		echo " $SPIP"
		echo -n "$QUESTION_VALID"
		read REPLY
		[ "$REPLY" = "y" ] || [ "$REPLY" = "o" ] || [ -z "$REPLY" ] || die $(eval_gettext "Erreur valide SPIP")
		echo
	else
		eval_gettext "Info MediaSPIP non installe"
	fi
	
	# ok, already, last check before proceeding
	echo "OK, nous sommes prêts à y aller ?"
	echo -n "$QUESTION_VALID"
	read REPLY
	[ "$REPLY" = "y" ] || [ "$REPLY" = "o" ] || [ -z "$REPLY" ] || die "exiting. Bye, did I come on too strong?."
	echo
fi

echo "Le script démarre" >> $LOG
echo "Installation des dépendances logicielles" 2>> $LOG >> $LOG


# Installation de plusieurs dependances 
# (librairies et binaires)
eval_gettext "Titre dependances logicielles"
echo
echo

"$DISTRIB"_"$DISTRO"_dep_install || error "$(eval_gettext 'Erreur installation regarde log $LOG')"

echo_reussite "$(eval_gettext 'End dependances')"
echo

# Préconfiguration basique d'Apache 
# (différents modules)

# Si on demande en option de ne pas configurer Apache, on ne le fait pas
if [ "$DISABLE_APACHE" != "yes" ];then
	eval_gettext "Titre apache"
	echo
	echo

	"$DISTRIB"_"$DISTRO"_apache_install || error "$(eval_gettext 'Erreur installation regarde log $LOG')"
	
	echo_reussite "$(eval_gettext 'End apache')"
	echo
fi

# Installation de x264
# librairie h.264 pour creer des videos compatibles html5 (Safari + iphone & co)
eval_gettext "Titre x264"
echo
echo

"$DISTRIB"_"$DISTRO"_x264_install || error "$(eval_gettext 'Erreur installation regarde log $LOG')"

echo
echo_reussite "$(eval_gettext 'End x264')"
echo

# Si on demande à ne pas installer FFMpeg, plusieurs autres logiciels ne seront pas installés :
# - FFMpeg lui-même
# - FFMpeg2theora
# - FFMpeg-php

if [ "$DISABLE_FFMPEG" != "yes" ];then

	# Installation de ffmpeg
	# binaire pour encoder videos et sons
	eval_gettext "Titre ffmpeg"
	echo
	echo
	
	"$DISTRIB"_"$DISTRO"_ffmpeg_install || error "$(eval_gettext 'Erreur installation regarde log $LOG')"
	
	echo
	echo_reussite "$(eval_gettext 'End ffmpeg')"
	echo
	
	# Installation de ffmpeg2theora
	# binaire plus simple que ffmpeg pour creer des fichiers ogg/theora
	eval_gettext "Titre ffmpeg2theora"
	echo
	echo
	
	"$DISTRIB"_"$DISTRO"_ffmpeg2theora_install || error "$(eval_gettext 'Erreur installation regarde log $LOG')"
	
	echo
	echo_reussite "$(eval_gettext 'End ffmpeg2theora')"
	echo
	
	# Installation de ffmpeg-php
	# extension ffmpeg pour php
	eval_gettext "Titre ffmpegphp"
	echo
	echo
	if [ -d "$SRC_INSTALL"/ffmpeg-php ];then
		echo $(eval_gettext "Info debut ffmpeg-php update")
		echo $(eval_gettext "Info debut ffmpeg-php update") 2>> $LOG >> $LOG
		"$DISTRIB"_"$DISTRO"_ffmpeg_php_update || error "$(eval_gettext 'Erreur installation regarde log $LOG')"
	else
		echo $(eval_gettext "Info debut ffmpeg-php install")
		echo $(eval_gettext "Info debut ffmpeg-php install") 2>> $LOG >> $LOG
		"$DISTRIB"_"$DISTRO"_ffmpeg_php_install || error "$(eval_gettext 'Erreur installation regarde log $LOG')"
	fi
	
	echo
	echo_reussite "$(eval_gettext 'End ffmpeg-php')"
fi

# On vérifie si alternc est sur le système
# Si oui on demande s'il est utilisé pour MediaSPIP
# Si oui, on cree des liens symboliques vers le répertoire du safe_mode
if [ -d /var/alternc/exec.usr ] && [ "$DISABLE_ALTERNC" != "yes" ]; then
	echo
	echo $(eval_gettext "Question alternc")
	echo -n "$QUESTION_VALID"
	read REPLY
	if([ "$REPLY" = "y" ] || [ "$REPLY" = "o" ] || [ -z "$REPLY" ]);then
		cd /var/alternc/exec.usr
		if [ ! -h vorbiscomment ];then
			ln -s /usr/bin/vorbiscomment 2>> $LOG >> $LOG 
		fi
		if [ ! -h metaflac ];then
			ln -s /usr/bin/metaflac 2>> $LOG >> $LOG
		fi
		if [ ! -h qt-faststart ];then
			ln -s /usr/local/bin/qt-faststart 2>> $LOG >> $LOG
		fi
		if [ ! -h ffmpeg2theora ];then
			ln -s /usr/local/bin/ffmpeg2theora 2>> $LOG >> $LOG
		fi
		if [ ! -h flvtool2 ];then
			ln -s /usr/bin/flvtool2 2>> $LOG >> $LOG
		fi
		if [ ! -h mediainfo ];then
			ln -s /usr/local/bin/mediainfo 2>> $LOG >> $LOG
		fi
		if [ ! -h ps ];then
			ln -s /bin/ps 2>> $LOG >> $LOG
		fi
		
		cd $CURRENT
		
		cp configs/spipmotion/spipmotion.sh /var/alternc/exec.usr/ 2>> $LOG >> $LOG
		chmod +x /var/alternc/exec.usr/spipmotion.sh
		
		echo
		echo_reussite "$(eval_gettext 'End alternc')"
	fi
fi

if [ "$DISABLE_MEDIASPIP" != "yes" ];then
	echo
	eval_gettext "Titre spip mediaspip"
	echo
	echo
	
	mediaspip_install || error "$(eval_gettext 'Erreur installation regarde log $LOG')"
fi

echo
echo_reussite "$(eval_gettext 'End installation generale')"
echo
exit 