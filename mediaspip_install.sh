#!/bin/bash
#
# mediaspip_install.sh
# © 2010 - kent1 (kent1@arscenic.info)
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


export TEXTDOMAINDIR=./locale
export TEXTDOMAIN=mediaspip

I18NLIB=/usr/bin/gettext.sh

# source in I18N library - shown above
if [[ -f $I18NLIB ]]
then
        . $I18NLIB
else
        echo "ERROR - $I18NLIB NOT FOUND"
        exit 1
fi

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

##########################################
# list of all the functions in the script
##########################################

echo "$LOGO"

#########################################
# Vérifications de base :
# - doit être lancé par root
# - doit être sur une debian 
#

if [ "$(id -u)" != "0" ]; then
	eval_gettext "Erreur script root" 1>&2
	exit 1
fi

if [ ! -r /etc/debian_version ]; then
	eval_gettext "Erreur script debian" 1>&2
	exit 1
fi

# On inclut le fichier de fonctions
. ./mediaspip_functions.sh
# On inclut le fichier d'installation de SPIP et de MediaSPIP
. ./mediaspip_spip_installation.sh

#########################################
# Variables éditables pour l'utilisateur
#

# Où sont téléchargées les sources
SRC_INSTALL="/usr/local/src"

# location of log file
LOG=/var/log/mediaspip_install.log

# location of the script's lock file
LOCK="/var/run/mediaspip_install.pid"

# Emplacement de SPIP
SPIP="/var/www/"

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
		eval_gettext "Help message"
		exit 0;;
		--lang|-lang) 
			case "${2}" in
				en) export LC_ALL="en_GB.UTF-8"
				shift;;
				fr) export LC_ALL="fr_FR.UTF-8"
				shift;;
				"") eval_gettext "Erreur langue non set"
				echo
				exit 0;;
				*) eval_gettext "Erreur langue inexistante"
				echo
				exit 0;;
			esac
		shift;;
		--version|-v) echo "MediaSPIP installation v."${VERSION}""
		exit 0;;
		--src_install|-src) SRC_INSTALL="${2}"
		shift;;
		--log|-l) LOG="${2}"
		shift;;
		--cpus|-c)
		if(isNumeric "${2}");then
			if ((${2} > $NO_OF_CPUCORES));then
				echo "Erreur : votre machine n'a pas autant de cpus (${2})"
				exit 1
			else 
				NO_OF_CPUCORES="${2}"
			fi
		else
			eval_gettext "Erreur option cpus numerique"
			exit 1
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
			echo "Votre type d'installation de MediaSPIP n'est pas disponible (${2})"
			exit 0
		fi
		shift;;
	esac
	shift
done

###############################
# Suite des fonctions du script
###############################

# Demande de valider l'emplacement des fichiers source des binaires
# Trois réponses valides possibles :
# - y
# - o
# - return (vide)
eval_gettext "Info source installation"
echo "$SRC_INSTALL"
read -p "Est-ce OK (o/n)?"
[ "$REPLY" == "y" ] || [ "$REPLY" == "o" ] || [ -z "$REPLY" ] || die "Erreur. Modifiez la variable SRC_INSTALL pour l'emplacement de votre choix."
echo

# Demande de valider l'emplacement des fichiers de log
# Trois réponses valides possibles :
# - y
# - o
# - return (vide)
echo "Ce script enregistrera ses logs dans :"
echo "$LOG"
read -p "Est-ce OK (o/n)?"
[ "$REPLY" == "y" ] || [ "$REPLY" == "o" ] || [ -z "$REPLY" ] || die "Erreur. Modifiez la variable LOG pour l'emplacement de votre choix."
echo

# Demande de valider l'emplacement des fichiers de SPIP et MediaSPIP
# Trois réponses valides possibles :
# - y
# - o
# - return (vide)
if [ "$SPIP_TYPE" != "none" ];then
	echo "Ce script installera SPIP dans le répertoire :"
	echo "$SPIP"
	read -p "Est-ce OK (o/n)?"
	[ "$REPLY" == "y" ] || [ "$REPLY" == "o" ] || [ -z "$REPLY" ] || die "Erreur. Modifiez la variable SPIP pour l'emplacement de votre choix."
	echo
else
	eval_gettext "Info MediaSPIP non installe"
fi

# ok, already, last check before proceeding
echo "OK, nous sommes prêts à y aller."
read -p "Dois-je procéder, rappelez-vous, il ne faut pas arrêter son exécution (o/n)?"
[ "$REPLY" == "y" ] || [ "$REPLY" == "o" ] || [ -z "$REPLY" ] || die "exiting. Bye, did I come on too strong?."

echo
echo "Allons y"
echo "Le script démarre" >> $LOG
echo "Installation des dépendances logicielles" 2>> $LOG >> $LOG


# Installation de plusieurs dépendances 
# (librairies et binaires)
eval_gettext "Titre dependances logicielles"

debian_dep_install || error "Erreur installation regarde log" &

progress_indicator $!

echo
eval_gettext "End dependances"
echo

# Installation de x264
# librairie h.264 pour créer des vidéos compatibles html5 (Safari + iphone & co)

eval_gettext "Titre x264"

if [ -d "$SRC_INSTALL"/x264 ];then
	echo "Mise à jour, compilation et installation de x264"
	echo "Mise à jour, compilation et installation de x264" 2>> $LOG >> $LOG
	debian_x264_update || error "Erreur installation regarde log" &
else 
	echo "Téléchargement, compilation et installation de x264"
	echo "Téléchargement, compilation et installation de x264" 2>> $LOG >> $LOG
	debian_x264_install || error "Erreur installation regarde log" &
fi

progress_indicator $!

eval_gettext "End x264"
echo

# Installation de ffmpeg
# binaire pour encoder vidéo et sons
eval_gettext "Titre ffmpeg"

if [ -d "$SRC_INSTALL"/ffmpeg/.svn ];then
	eval_gettext "Info debut ffmpeg update"
	eval_gettext "Info debut ffmpeg update" 2>> $LOG >> $LOG
	debian_ffmpeg_update || error "Erreur installation regarde log" &
else 
	eval_gettext "Info debut ffmpeg install"
	eval_gettext "Info debut ffmpeg install" 2>> $LOG >> $LOG
	debian_ffmpeg_install || error "Erreur installation regarde log" &
fi

progress_indicator $!

eval_gettext "End ffmpeg"
echo

# Installation de ffmpeg2theora
# binaire plus simple que ffmpeg pour créer des fichiers ogg/theora
eval_gettext "Titre ffmpeg2theora"

if [ -d "$SRC_INSTALL"/ffmpeg2theora/.svn ];then
	eval_gettext "Info debut ffmpeg2theora update"
	eval_gettext "Info debut ffmpeg2theora update" 2>> $LOG >> $LOG
	debian_ffmpeg2theora_update || error "Erreur installation regarde log" &
else 
	eval_gettext "Info debut ffmpeg2theora install"
	eval_gettext "Info debut ffmpeg2theora install" 2>> $LOG >> $LOG
	debian_ffmpeg2theora_install || error "Erreur installation regarde log" &
fi

progress_indicator $!

eval_gettext "End ffmpeg2theora"

echo

# Installation de ffmpeg-php
# extension ffmpeg pour php
eval_gettext "Titre ffmpegphp"

if [ -d "$SRC_INSTALL"/ffmpeg-php ];then
	eval_gettext "Info debut ffmpeg-php update"
	eval_gettext "Info debut ffmpeg-php update" 2>> $LOG >> $LOG
	debian_ffmpeg_php_update || error "Erreur installation regarde log" &
else
	eval_gettext "Info debut ffmpeg-php install"
	eval_gettext "Info debut ffmpeg-php install" 2>> $LOG >> $LOG
	debian_ffmpeg_php_install || error "Erreur installation regarde log" &
fi

progress_indicator $!

eval_gettext "End ffmpeg-php"

# On vérifie si alternc est sur le système
# Si oui on demande s'il est utilisé pour MediaSPIP
# Si oui, on crée des liens symboliques vers le répertoire du safe_mode
if [ -d /var/alternc/exec.usr ]; then
	echo
	echo "Utilisez vous AlternC pour MediaSPIP ?"
	read -p "Yes/No (y/n)?"
	if [ "$REPLY" == y ];then
		cd /var/alternc/exec.usr
		ln -s /usr/bin/vorbiscomment 2>> $LOG >> $LOG
		ln -s /usr/bin/metaflac 2>> $LOG >> $LOG
		ln -s /usr/local/bin/ffmpeg 2>> $LOG >> $LOG
		ln -s /usr/local/bin/qt-faststart 2>> $LOG >> $LOG
		ln -s /usr/local/bin/ffmpeg2theora 2>> $LOG >> $LOG
		ln -s /usr/bin/flvtool2 2>> $LOG >> $LOG
		ln -s /usr/local/bin/mediainfo 2>> $LOG >> $LOG
		ln -s /bin/ps 2>> $LOG >> $LOG
		echo -e "\bCréation des liens symboliques des binaires pour AlternC terminée"
	fi
fi

eval_gettext "Titre spip mediaspip"

mediaspip_install

echo
echo "L'installation est terminée."

exit 