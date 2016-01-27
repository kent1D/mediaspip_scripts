#!/bin/bash
#
# mediaspip_install.sh
# © 2011-2016 - kent1 (kent1@arscenic.info)
# Version 0.9.2
# 
# Ce script installe toutes les dépendances logicielles nécessaires au bon fonctionnement de MediaSPIP :
# - Apache2
# - Mysql
# - php5-gd2;
# - php5-curl;
# - php5-imagick;
# - libx264;
# - lame;
# - libopencore-amr;
# - libtheora;
# - rtmpdump;
# - flvtool++;
# - mediainfo;
# - ffmpeg;
#   - libvpx
#   - libfdk_aac
# - ...
#
# Ce script installe également SPIP et l'ensemble des extensions nécessaires, plugins optionnels et thèmes pour MediaSPIP
# Il installe également :
# - le nécessaire pour réaliser une mutualisation (ferme) de SPIP;
# - l'écran de sécurité de SPIP;
#
# Voir CHANGELOG.md 

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

VERSION_INSTALL="0.9.2"

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
	DISTRIB_VERSION=$(cat /etc/debian_version)
	NUMBER=$(cat /etc/debian_version | cut -c 1)
	if [ "$NUMBER" = '6' ]; then
		DISTRO="squeeze"
	elif [ "$NUMBER" = '7' ]; then
		DISTRO="wheezy"
	elif [ "$DISTRIB_VERSION" = 'wheezy/sid' ]; then
		DISTRO="wheezy"
	else
		echo_erreur "$(eval_gettext 'Erreur script distro inconnue')"
		exit 1
	fi
# Cas de redhat (?) et centos
elif [ -r /etc/redhat-release ]; then
	DISTRIB=$(cat /etc/redhat-release |awk  '{ print $1 }' | tr '[A-Z]' '[a-z]' | tr '[:punct:]' '_')
	DISTRO=$(cat /etc/redhat-release |awk  '{ print $3 }' | tr '[A-Z]' '[a-z]' | tr '[:punct:]' '_')
elif [ -x $(which sw_vers) ]; then
	DISTRIB="osx"
	DISTRO=$($(which sw_vers) -productVersion | awk -F '.' '{print $1 "." $2}')
else
	echo_erreur "$(eval_gettext 'Erreur script distro inconnue')"
	exit 1
fi

OKDISTRO='squeeze wheezy precise trusty jessie';
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

# Emplacement final de SPIP et MediaSPIP
SPIP="/var/www/mediaspip"

# Version de SPIP (svn ou stable)
SPIP_VERSION="svn"
SPIP_TYPE="ferme_full"
SPIP_SVN="svn://trac.rezo.net/spip/branches/spip-3.0"

#if [ "$DISTRIB" = "centos" ];then
#	SPIP_USER="apache"
#	SPIP_GROUP="apache"
#else
	SPIP_USER="www-data"
	SPIP_GROUP="www-data"
#fi

# Forcer ffmpeg à se réinstaller, cas où modif libvpx et x264
FFMPEG_FORCE_INSTALL="non"

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
				en) export LC_MESSAGES=en_US.UTF-8
				shift 2;;
				fr) export LC_MESSAGES=fr_FR.UTF-8
				shift 2;;
				"") echo_erreur "$(eval_gettext 'Erreur langue non set')"
				ERROR=oui
				shift 2;;
				*) echo_erreur "$(eval_gettext 'Erreur langue inexistante')"
				ERROR=oui
				shift;;
			esac
		;;
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
		--disable-alternc) DISABLE_ALTERNC="yes"
		echo $(eval_gettext 'Info options disable_alternc')
		shift;;
		--disable-apache) DISABLE_APACHE="yes"
		echo $(eval_gettext 'Info options disable_apache')
		shift;;
		--disable-ffmpeg) DISABLE_FFMPEG="yes"
		echo $(eval_gettext 'Info options disable_ffmpeg')
		shift;;
		--disable-mediaspip) 
		DISABLE_MEDIASPIP="yes"
		SPIP_TYPE="none"
		echo $(eval_gettext 'Info options disable_mediaspip')
		shift;;
		--disable-munin) DISABLE_MUNIN="yes"
		echo $(eval_gettext 'Info options disable_munin')
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

# Si LC_MESSAGES n'est pas en en ni fr, on le force en en
LANGUES_COMPAT='en fr'
if [ -n "${LC_MESSAGES}" ]; then
	LANGUE=`expr substr $LC_MESSAGES 1 2`
elif [ -n "${LANG}" ]; then
	LANGUE=`expr substr $LANG 1 2`
	export LC_MESSAGES=$LANG
else
	LANGUE=''
fi
case $LANGUE in
	en|fr) ;;
	*)
		export LC_MESSAGES=en_US.UTF-8
		;;
esac 

verif_internet_connexion || error "$(eval_gettext 'Erreur internet connexion')"

if [ "$(id -u)" != "0" ]; then
	echo_erreur "$(eval_gettext 'Erreur script root')" 1>&2
	exit 1
fi

if [ "$ERROR" = "oui" ]; then
	exit 1
fi

##
# FFmpeg : http://ffmpeg.org/download.html
##
FFMPEG_VERSION="2.8.5"
FFMPEG_URL="http://ffmpeg.org/releases/ffmpeg-2.8.5.tar.bz2"
FFMPEG_FICHIER="ffmpeg-2.8.5.tar.bz2"
FFMPEG_PATH="ffmpeg-2.8.5"

##
# MediaInfo : https://mediaarea.net/fr/MediaInfo/Download/Source
##
MEDIAINFO_VERSION="0.7.81"
MEDIAINFO_URL="http://mediaarea.net/download/binary/mediainfo/0.7.81/MediaInfo_CLI_0.7.81_GNU_FromSource.tar.bz2"
MEDIAINFO_FICHIER="MediaInfo_CLI_0.7.81_GNU_FromSource.tar.bz2"
MEDIAINFO_PATH="MediaInfo_CLI_GNU_FromSource"

##
# FLVtool++
##
FLVTOOLPLUS_VERSION="1.2.1"
FLVTOOLPLUS_URL="http://files.mediaspip.net/binaires/flvtool++-1.2.1.tar.gz"
FLVTOOLPLUS_FICHIER="flvtool++-1.2.1.tar.gz"
FLVTOOLPLUS_PATH="flvtool++-1.2.1"

##
# LibOpus : http://www.opus-codec.org/downloads/
##
LIBOPUS_VERSION="1.1.1"
LIBOPUS_URL="http://downloads.xiph.org/releases/opus/opus-1.1.1.tar.gz"
LIBOPUS_FICHIER="opus-1.1.1.tar.gz"
LIBOPUS_PATH="opus-1.1.1"

##
# LibFDK-aac : https://github.com/mstorsjo/fdk-aac/releases
##
LIBFDKAAC_VERSION="0.1.4"
LIBFDKAAC_URL="https://github.com/mstorsjo/fdk-aac/archive/v0.1.4.tar.gz"
LIBFDKAAC_FICHIER="v0.1.4.tar.gz"
LIBFDKAAC_PATH="fdk-aac-0.1.4"

##
# Libvpx : https://github.com/webmproject/libvpx/releases
##
LIBVPX_VERSION="1.5.0"
LIBVPX_URL="https://github.com/webmproject/libvpx/archive/v1.5.0.tar.gz"
LIBVPX_FICHIER="v1.5.0.tar.gz"
LIBVPX_PATH="libvpx-1.5.0"

FICHIER="distribs/$DISTRIB_$DISTRO.sh"
. ./distribs/"$DISTRIB"_"$DISTRO".sh 2>> $LOG >> $LOG || error "$(eval_gettext 'Erreur fichier $FICHIER')"

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

# Si on demande à ne pas installer FFMpeg, plusieurs autres logiciels ne seront pas installés :
# - FFMpeg lui-même

if [ "$DISABLE_FFMPEG" != "yes" ];then
	# Installation de x264
	# librairie h.264 pour creer des videos compatibles html5 (Safari + iphone & co)
	eval_gettext "Titre x264"
	echo
	echo
	
	"$DISTRIB"_"$DISTRO"_x264_install || error "$(eval_gettext 'Erreur installation regarde log $LOG')"
	SOFT="libx264"
	echo
	echo_reussite "$(eval_gettext 'End $SOFT')"
	echo

	# Installation de ffmpeg
	# binaire pour encoder videos et sons
	eval_gettext "Titre ffmpeg"
	echo
	echo
	
	# On a besoin de ce répertoire et checkinstall ne sait le créer
	if [ ! -d "/usr/local/share/" ];then
		mkdir -p /usr/local/share/
	fi
	"$DISTRIB"_"$DISTRO"_ffmpeg_install || error "$(eval_gettext 'Erreur installation regarde log $LOG')"
	SOFT="ffmpeg"
	echo
	echo_reussite "$(eval_gettext 'End $SOFT')"
	echo

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

# Munin est présent
# On installe mediaspip_munin
# cf : mediaspip_functions.sh
if [ -n "$DISABLE_MUNIN" ] && [ "$DISABLE_MUNIN" != "yes" -a -x $(which munin-node) ];then
	mediaspip_munin_install || error "$(eval_gettext 'Erreur installation regarde log $LOG')"
fi

echo
echo_reussite "$(eval_gettext 'End installation generale')"
echo
exit