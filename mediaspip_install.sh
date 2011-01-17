#!/bin/bash
#
# mediaspip_install.sh
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.2
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
# Ce script installe également SPIP et l'ensemble des extensions nécessaires à MediaSPIP

export TEXTDOMAINDIR=$(pwd)/locale
export TEXTDOMAIN=mediaspip

I18NLIB=/usr/bin/gettext.sh

# source in I18N library - shown above
if [[ -f $I18NLIB ]]; then
	. $I18NLIB
else
	echo "ERROR - $I18NLIB NOT FOUND"
	exit 1
fi

# On inclut le fichier de fonctions
if [[ -f "./mediaspip_functions.sh" ]]; then
	. ./mediaspip_functions.sh
else
	echo $(eval_gettext "Erreur fichier fonctions")
	exit 1
fi
# On inclut le fichier d'installation de SPIP et de MediaSPIP
. ./mediaspip_spip_installation.sh

VERSION="0.2"

LOGO="
######################################################################################


.___  ___.  _______  _______   __       ___           _______..______    __  .______   
|   \/   | |   ____||       \ |  |     /   \         /       ||   _  \  |  | |   _  \  
|  \  /  | |  |__   |  .--.  ||  |    /  ^  \       |   (----\`|  |_)  | |  | |  |_)  | 
|  |\/|  | |   __|  |  |  |  ||  |   /  /_\  \       \   \    |   ___/  |  | |   ___/  
|  |  |  | |  |____ |  '--'  ||  |  /  _____  \  .----)   |   |  |      |  | |  |      
|__|  |__| |_______||_______/ |__| /__/     \__\ |_______/    | _|      |__| | _|     

VERSION ${VERSION}

######################################################################################
"

if [ -d "fun" ];then
	set -- fun/*
	length=$#
	random_num=$(( $RANDOM % ($length + 1) ))
	. ${!random_num}
fi

tput setaf 2;
echo "$LOGO"
tput sgr0;

#########################################
# Vérifications de base :
# - doit être lancé par root
# - doit être sur une debian 
#

if [ "$(id -u)" != "0" ]; then
	echo_erreur $(eval_gettext "Erreur script root") 1>&2
	exit 1
fi

if [ ! -r /etc/debian_version ]; then
	echo_erreur $(eval_gettext "Erreur script debian") 1>&2
	exit 1
fi

# On pose une variable sur le répertoire courant permettant de savoir 
# d'où le script est lancé
CURRENT=$(pwd)

# On vérifie que l'on a bien accès au programme pkg-config 
# Il permet de connaitre les versions des librairies sur le système
PKG_CONFIG=$(which pkg-config)

if [ ! -x $PKG_CONFIG ]; then
	echo_erreur 'pkg-config pas installé'
	exit 1
fi

#########################################
# Variables éditables pour l'utilisateur
#

# Où sont téléchargées les sources
SRC_INSTALL="/usr/local/src"

# location of log file
LOG=/var/log/mediaspip_install.log

# location of the script's lock file
LOCK="/var/run/mediaspip_install.pid"

# Emplacement final de SPIP et MediaSPIP
SPIP="/var/www/mediaspip"

# Version de SPIP (svn ou stable)
SPIP_VERSION="svn"
SPIP_TYPE="ferme_full"
SPIP_SVN="svn://trac.rezo.net/spip/branches/spip-2.1"
SPIP_USER="www-data"
SPIP_GROUP="www-data"
SPIP_TYPES=(ferme_full ferme minimal full none)

# On récupère le nombre de cores de la machine pour les utiliser lors des compilations
NO_OF_CPUCORES=`grep -c ^processor /proc/cpuinfo 2>/dev/null`
if [ ! "$?" = "0" ]
then
    NO_OF_CPUCORES=2
fi

while test -n "${1}"; do
	case "${1}" in
		--help|-h) 
		echo $(eval_gettext "Help message")
		exit 0;;
		--lang|-lang) 
			case "${2}" in
				en) export LC_ALL="en_GB.UTF-8"
				shift;;
				fr) export LC_ALL="fr_FR.UTF-8"
				shift;;
				"") echo_erreur $(eval_gettext "Erreur langue non set")
				ERROR=oui
				shift;;
				*) echo_erreur $(eval_gettext "Erreur langue inexistante")
				ERROR=oui
				shift;;
			esac
		shift;;
		--version|-v) echo $(eval_gettext 'Info mediaspip installation $VERSION')  
		exit 0;;
		--src_install|-src) SRC_INSTALL="${2}"
		shift;;
		--log|-l) LOG="${2}"
		shift;;
		--cpus|-c)
			if [ ! -z "${2}" ];then
				if(isNumeric "${2}");then
					if ((${2} > $NO_OF_CPUCORES));then
						CPU_NB=${2}
						echo_erreur $(eval_gettext 'Erreur option cpus trop $CPU_NB')  
						ERROR=oui
					else 
						NO_OF_CPUCORES="${2}"
					fi
				else
					echo_erreur $(eval_gettext "Erreur option cpus numerique")
					ERROR=oui
				fi
			else
				echo_erreur $(eval_gettext "Erreur option cpus numerique")
				ERROR=oui
			fi
		shift;;
		--spip|-s) SPIP="${2}"
		shift;;
		--spip_version|-s_v) SPIP_VERSION="${2}"
		shift;;
		--spip_svn|-s_svn) SPIP_VERSION="${2}"
		shift;;
		--spip_user) SPIP_USER="${2}"
		shift;;
		--spip_group) SPIP_GROUP="${2}"
		shift;;
		--spip_type)
		if in_array ${2} ${SPIP_TYPES[@]};then
			SPIP_TYPE=${2}
		else
			TYPEDEMANDE=${2}
			echo_erreur $(eval_gettext 'Erreur mediaspip type disponible $TYPEDEMANDE')
			ERROR=oui
		fi
		shift;;
	esac
	shift
done

if [ "$ERROR" == "oui" ]; then
	exit 1
fi

###############################
# Suite des fonctions du script
###############################

QUESTION_VALID=$(eval_gettext "Question valider")

# Demande de valider l'emplacement des fichiers source des binaires
# Trois reponses valides possibles :
# - y
# - o
# - return (vide)
eval_gettext "Info source installation"
echo " $SRC_INSTALL"
read -p "$QUESTION_VALID"
[ "$REPLY" == "y" ] || [ "$REPLY" == "o" ] || [ -z "$REPLY" ] || die $(eval_gettext "Erreur valide SRC_INSTALL")
echo

# Demande de valider l'emplacement des fichiers de log
# Trois reponses valides possibles :
# - y
# - o
# - return (vide)
eval_gettext "Info log installation"
#echo ""
echo " $LOG"
read -p "$QUESTION_VALID"
[ "$REPLY" == "y" ] || [ "$REPLY" == "o" ] || [ -z "$REPLY" ] || die $(eval_gettext "Erreur valide LOG")
echo

# Demande de valider l'emplacement des fichiers de SPIP et MediaSPIP
# Trois reponses valides possibles :
# - y
# - o
# - return (vide)
if [ "$SPIP_TYPE" != "none" ];then
	eval_gettext "Info SPIP installation"
	echo " $SPIP"
	read -p "$QUESTION_VALID"
	[ "$REPLY" == "y" ] || [ "$REPLY" == "o" ] || [ -z "$REPLY" ] || die $(eval_gettext "Erreur valide SPIP")
	echo
else
	eval_gettext "Info MediaSPIP non installe"
fi

# ok, already, last check before proceeding
echo "OK, nous sommes prêts à y aller."
read -p "Dois-je procéder, rappelez-vous, il ne faut pas arrêter son exécution (o/n)?"
[ "$REPLY" == "y" ] || [ "$REPLY" == "o" ] || [ -z "$REPLY" ] || die "exiting. Bye, did I come on too strong?."

echo
echo "Le script démarre" >> $LOG
echo "Installation des dépendances logicielles" 2>> $LOG >> $LOG


# Installation de plusieurs dependances 
# (librairies et binaires)
eval_gettext "Titre dependances logicielles"
echo
echo

debian_dep_install || error $(eval_gettext "Erreur installation regarde log") &
progress_indicator $!

echo_reussite $(eval_gettext "End dependances")
echo

# Installation de x264
# librairie h.264 pour creer des videos compatibles html5 (Safari + iphone & co)
eval_gettext "Titre x264"
echo
echo
if [ -d "$SRC_INSTALL"/x264 ];then
	echo $(eval_gettext "Info debut x264 update")
	echo
	echo $(eval_gettext "Info debut x264 update") 2>> $LOG >> $LOG
	debian_x264_update || error $(eval_gettext "Erreur installation regarde log") &
else
	echo $(eval_gettext "Info debut x264 install")
	echo
	echo $(eval_gettext "Info debut x264 install") 2>> $LOG >> $LOG
	debian_x264_install || error $(eval_gettext "Erreur installation regarde log") &
fi

progress_indicator $!

echo
echo_reussite $(eval_gettext "End x264")
echo

# Installation de ffmpeg
# binaire pour encoder videos et sons
eval_gettext "Titre ffmpeg"
echo
echo

if [ -d "$SRC_INSTALL"/ffmpeg/.svn ];then
	echo $(eval_gettext "Info debut ffmpeg update")
	echo
	echo $(eval_gettext "Info debut ffmpeg update") 2>> $LOG >> $LOG
	debian_ffmpeg_update || error $(eval_gettext "Erreur installation regarde log") &
else 
	echo $(eval_gettext "Info debut ffmpeg install")
	echo
	echo $(eval_gettext "Info debut ffmpeg install") 2>> $LOG >> $LOG
	debian_ffmpeg_install || error $(eval_gettext "Erreur installation regarde log") &
fi

progress_indicator $!

echo
echo_reussite $(eval_gettext "End ffmpeg")
echo

# Installation de ffmpeg2theora
# binaire plus simple que ffmpeg pour creer des fichiers ogg/theora
eval_gettext "Titre ffmpeg2theora"
echo
echo

if [ -d "$SRC_INSTALL"/ffmpeg2theora/.svn ];then
	echo $(eval_gettext "Info debut ffmpeg2theora update")
	echo $(eval_gettext "Info debut ffmpeg2theora update") 2>> $LOG >> $LOG
	debian_ffmpeg2theora_update || error $(eval_gettext "Erreur installation regarde log") &
else
	echo $(eval_gettext "Info debut ffmpeg2theora install")
	echo $(eval_gettext "Info debut ffmpeg2theora install") 2>> $LOG >> $LOG
	debian_ffmpeg2theora_install || error $(eval_gettext "Erreur installation regarde log") &
fi

progress_indicator $!

echo
echo_reussite $(eval_gettext "End ffmpeg2theora")
echo

# Installation de ffmpeg-php
# extension ffmpeg pour php
eval_gettext "Titre ffmpegphp"
echo
echo
if [ -d "$SRC_INSTALL"/ffmpeg-php ];then
	echo $(eval_gettext "Info debut ffmpeg-php update")
	echo $(eval_gettext "Info debut ffmpeg-php update") 2>> $LOG >> $LOG
	debian_ffmpeg_php_update || error $(eval_gettext "Erreur installation regarde log") &
	progress_indicator $!
else
	echo $(eval_gettext "Info debut ffmpeg-php install")
	echo $(eval_gettext "Info debut ffmpeg-php install") 2>> $LOG >> $LOG
	debian_ffmpeg_php_install || error $(eval_gettext "Erreur installation regarde log") &
	progress_indicator $!
fi

echo
echo_reussite $(eval_gettext "End ffmpeg-php")
echo

# On vérifie si alternc est sur le système
# Si oui on demande s'il est utilisé pour MediaSPIP
# Si oui, on cree des liens symboliques vers le répertoire du safe_mode
if [ -d /var/alternc/exec.usr ]; then
	echo
	echo $(eval_gettext "Question alternc")
	read -p "$QUESTION_VALID"
	if([ "$REPLY" == "y" ] || [ "$REPLY" == "o" ] || [ -z "$REPLY" ]);then
		cd /var/alternc/exec.usr
		if [ ! -h vorbiscomment ];then
			ln -s /usr/bin/vorbiscomment 2>> $LOG >> $LOG 
		fi
		if [ ! -h metaflac ];then
			ln -s /usr/bin/metaflac 2>> $LOG >> $LOG
		fi
		if [ ! -h ffmpeg ];then
			ln -s /usr/local/bin/ffmpeg 2>> $LOG >> $LOG
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
		if [ ! -h /var/alternc/exec.usr/mediainfo ];then
			ln -s /usr/local/bin/mediainfo 2>> $LOG >> $LOG
		fi
		if [ ! -h ps ];then
			ln -s /bin/ps 2>> $LOG >> $LOG
		fi
		cd $CURRENT
		echo
		echo_reussite $(eval_gettext "End alternc")
	fi
fi

echo
eval_gettext "Titre spip mediaspip"
echo
echo

mediaspip_install || error $(eval_gettext "Erreur installation regarde log") &
progress_indicator $!

echo
echo_reussite $(eval_gettext "End installation generale")
echo
exit 