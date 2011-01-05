#!/bin/bash
#
# mediaspip_install.sh
# © 2010 - kent1 (kent1@arscenic.info)
# Version 0.1
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

VERSION="0.1"

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

MESSAGEAIDE="Copyright (c) 2010 - kent1

Ce programme est un logiciel libre distribué sous licence GNU/GPL.
Pour plus de détails voir le fichier COPYING.txt.

EXPLICATIONS :

Ce script installera toutes les dépendances logicielles requises pour l'installation de 
mediaSPIP.

Il installera ensuite le logiciels SPIP (http://www.spip.net) ainsi que les extensions 
nécessaires dans le répertoire d'installation spécifié.

Les paramètres possibles du scripts sont :
--install : l'emplacement où les sources des librairies et binaires seront téléchargés
--cpus : permet de forcer le nombre de cpus à utiliser pour les compilations
--spip_type : type d'installation de MediaSPIP (ferme|ferme_full|minimal|full|none). Défaut : ferme_full
--spip_user : utilisateur système (UID) des fichiers de MediaSPIP
--spip_group : groupe système (GID) des fichiers de MediaSPIP
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
	echo "Erreur. Ce script doit être lancé en tant que root" 1>&2
	exit 1
fi

if [ ! -r /etc/debian_version ]; then
	echo "Erreur. Vous ne semblez pas être sur une Distribution Debian" 1>&2
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
INSTALL="/usr/local/src"
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

# Speed up build time using multpile processor cores.
NO_OF_CPUCORES=`grep -c ^processor /proc/cpuinfo 2>/dev/null`
if [ ! "$?" = "0" ]
then
    NO_OF_CPUCORES=2
fi

while test -n "${1}"; do
	case "${1}" in
		--help|-h) echo "$MESSAGEAIDE"
		exit 0;;
		--version|-v) echo "MediaSPIP installation v."${VERSION}""
		exit 0;;
		--install|-i) INSTALL="${2}"
		shift;;
		--log|-l) LOG="${2}"
		shift;;
		--cpus|-c)
		if(isNumeric "${2}");then
			if ((${2} > $NO_OF_CPUCORES));then
				echo "Erreur : votre machine n'a pas autant de cpus (${2})"
				exit 0
			else 
				NO_OF_CPUCORES="${2}"
			fi
		else
			echo "Erreur : votre option --cpus n'est pas numérique"
			exit 0
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

debian_dep_install()
{
	echo "Mise à jour de la base d'APT" 2>> $LOG >> $LOG
	apt-get -y update 2>> $LOG >> /dev/null
	echo "Installation ou mise à jour des paquets via APT" 2>> $LOG  >> $LOG
	apt-get -y install build-essential subversion git-core checkinstall php5-dev ruby yasm texi2html libfaac-dev libfaad-dev libdirac-dev libgsm1-dev libopenjpeg-dev libxvidcore4-dev libschroedinger-dev libspeex-dev libvorbis-dev flac vorbis-tools zlib1g-dev php5-curl php5-gd php5-imagick scons liboggkate-dev libcxxtools-dev 2>> $LOG  >> /dev/null
	
	debian_lame_install
	
	debian_libopencore_amr_install
	
	debian_libtheora_install
	
	debian_rtmpdump_install
	
	debian_flvtool_install
	
	debian_media_info_install
}

#install x264
debian_x264_install ()
{
	apt-get -y remove x264 libx264-dev 2>> $LOG  >> /dev/null
	cd $INSTALL
	git clone git://git.videolan.org/x264.git 2>> $LOG  >> /dev/null
	cd x264
	./configure --enable-shared 2>> $LOG  >> /dev/null
	make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
	checkinstall --pkgname=x264 --pkgversion "1:0.svn`date +%Y%m%d`-0.0lenny2" --backup=no --default 2>> $LOG  >> /dev/null
}

debian_x264_update ()
{
	apt-get -y remove x264 2>> $LOG >> $LOG
	cd "$INSTALL"/x264
	git pull 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES distclean 2>> $LOG  >> /dev/null
	./configure --enable-shared 2>> $LOG  >> /dev/null
	make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
	checkinstall --pkgname=x264 --pkgversion "1:0.svn`date +%Y%m%d`-0.0lenny2" --backup=no --default 2>> $LOG  >> /dev/null
}

#install ffmpeg
debian_ffmpeg_install ()
{
	apt-get -y remove ffmpeg 2>> $LOG >> $LOG
	cd $INSTALL
	svn checkout svn://svn.ffmpeg.org/ffmpeg/trunk ffmpeg 2>> $LOG >> $LOG
	cd ffmpeg
	make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
	./configure --enable-gpl --enable-version3 --enable-nonfree --enable-shared --enable-postproc --enable-pthreads --enable-libfaac --enable-libmp3lame --enable-libxvid --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libdirac --enable-libspeex --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib 2>> $LOG >> /dev/null																															      
	make -j $NO_OF_CPUCORES 2>> $LOG >> /dev/null
	checkinstall --pkgname=ffmpeg --pkgversion "3:0.svn`date +%Y%m%d`-18lenny2" --backup=no --default 2>> $LOG >> $LOG
	cd tools
	cc qt-faststart.c -o qt-faststart
	cd ..
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo
	echo ffmpeg is at revision $REVISION
}

debian_ffmpeg_update ()
{
	cd $INSTALL/ffmpeg
	svn up 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')  2>> $LOG >> $LOG
	#FFMPEG=$(which ffmpeg) 2>> $LOG >> $LOG
	if [ -x /usr/local/bin/ffmpeg ];then
		VERSION=$(ffmpeg -version  2> /dev/null |grep FFmpeg -m 1 |awk '{print $2}')  2>> $LOG >> $LOG
		REVISION_VERSION=SVN-r"$REVISION"
		if [ "$VERSION" = "$REVISION_VERSION" ];then
			echo "FFmpeg est déjà à jour"
		else
			apt-get -y remove ffmpeg  2>> $LOG >> $LOG
			make -j $NO_OF_CPUCORES clean 2>> $LOG >> /dev/null
			make -j $NO_OF_CPUCORES distclean 2>> $LOG >> /dev/null
			./configure --enable-gpl --enable-version3 --enable-nonfree --enable-shared --enable-postproc --enable-pthreads --enable-libfaac --enable-libmp3lame --enable-libxvid --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libdirac --enable-libspeex --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib 2>> $LOG >> /dev/null																															      
			make -j $NO_OF_CPUCORES 2>> $LOG >> /dev/null
			checkinstall --pkgname=ffmpeg --pkgversion "3:0.svn`date +%Y%m%d`-18lenny2" --backup=no --default 2>> $LOG >> /dev/null
			ldconfig
			cd tools
			cc qt-faststart.c -o qt-faststart
			cp qt-faststart /usr/local/bin
		fi
	else
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> /dev/null
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> /dev/null
		./configure --enable-gpl --enable-version3 --enable-nonfree --enable-postproc --enable-pthreads --enable-libfaac --enable-libmp3lame --enable-libxvid --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libdirac --enable-libspeex --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib 2>> $LOG >> /dev/null																															      
		make -j $NO_OF_CPUCORES 2>> $LOG >> /dev/null
		checkinstall --pkgname=ffmpeg --pkgversion "3:0.svn`date +%Y%m%d`-18lenny2" --backup=no --default 2>> $LOG >> $LOG
		ldconfig
		cd tools
		cc qt-faststart.c -o qt-faststart
		cp qt-faststart /usr/local/bin
	fi
	echo
	echo "FFMpeg est installé à la révision $REVISION"
}

debian_ffmpeg2theora_install ()
{
	apt-get -y remove ffmpeg2theora 2>> $LOG >> $LOG
	cd $INSTALL
	svn checkout http://svn.xiph.org/trunk/ffmpeg2theora ffmpeg2theora 2>> $LOG >> $LOG
	cd ffmpeg2theora
	# Install une version récente de libkate
	sh ./get_libkate.sh
	scons install 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo
	echo "ffmpeg2theora est installé à la révision $REVISION"
}

debian_ffmpeg2theora_update ()
{
	cd "$INSTALL"/ffmpeg2theora
	svn up 2>> $LOG >> $LOG
	scons install 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo
	echo "ffmpeg2theora est installé à la révision $REVISION"
}

#install ffmpeg
debian_ffmpeg_php_install ()
{
	apt-get -y remove ffmpeg-php 2>> $LOG >> $LOG
	cd $INSTALL
	svn co https://ffmpeg-php.svn.sourceforge.net/svnroot/ffmpeg-php/trunk ffmpeg-php 2>> $LOG >> $LOG
	cd ffmpeg-php/ffmpeg-php
	phpize
	make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
	./configure && make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
	make install
	echo 'extension=ffmpeg.so' > /etc/php5/conf.d/ffmpeg.ini
	/etc/init.d/apache2 force-reload
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo
	echo "FFMpeg-php est installé à la révision $REVISION"
}

debian_ffmpeg_php_update ()
{
	cd "$INSTALL"/ffmpeg-php/ffmpeg-php
	OLDREVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')  2>> $LOG >> $LOG
	svn up 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')  2>> $LOG >> $LOG
	#FFMPEG=$(which ffmpeg) 2>> $LOG >> $LOG
	if [ "$OLDREVISION" = "$REVISION" ];then
		echo "FFmpeg-php est déja à jour"
	else
		phpize
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		./configure && make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		make install
		echo 'extension=ffmpeg.so' > /etc/php5/conf.d/ffmpeg.ini
		/etc/init.d/apache2 force-reload
	fi
	echo "FFMpeg-php est installé à la révision $REVISION"
}


#exit function
die ()
{
	echo $@ 
	exit 1
}

#error function
error ()
{
	kill "$PID" &>/dev/null 2>> $LOG >> $LOG
	
	echo $1
	echo $@
	exit 1
}

###############
# this is the body of the script
###############

# check that the default place to download to and log file location is ok
echo "Ce script téléchargera les sources des logiciels dans :"
echo "$INSTALL"
read -p "Est-ce OK (y/n)?"
[ "$REPLY" == y ] || die "Erreur. Modifiez la variable INSTALL pour l'emplacement de votre choix."
echo

echo "Ce script enregistrera ses logs dans :"
echo "$LOG"
read -p "Est-ce OK (y/n)?"
[ "$REPLY" == y ] || die "Erreur. Modifiez la variable LOG pour l'emplacement de votre choix."
echo

# Verifie le chemin d'installation de SPIP
echo "Ce script installera SPIP dans le répertoire :"
echo "$SPIP"
read -p "Est-ce OK (y/n)?"
[ "$REPLY" == y ] || die "Erreur. Modifiez la variable SPIP pour l'emplacement de votre choix."
echo

# ok, already, last check before proceeding
echo "OK, nous sommes prêts à y aller."
read -p "Dois-je procéder, rappelez-vous, il ne faut pas arrêter son exécution (y/n)?"
[ "$REPLY" == y ] || die "exiting. Bye, did I come on too strong?."

echo
echo "Allons y"
echo "Le script démarre" >> $LOG
echo "Installation des dépendances logicielles" 2>> $LOG >> $LOG
echo "
############################################
# Installation des dépendances logicielles #
############################################
"
debian_dep_install || error "Sorry something went wrong, please check the $LOG file." &
PID=$!
#this is a simple progress indicator
while ps |grep $PID &>/dev/null; do
	echo -n "."
	echo -en "\b-"
	sleep 1
	echo -en "\b\\"
	sleep 1
	echo -en "\b|"
	sleep 1
	echo -en "\b/"
	sleep 1
done

echo -e "\bFin de l'installation des dépendances"
echo
echo "
############################################
#     Installation de libx264 et x264      #
############################################
"
if [ -d "$INSTALL"/x264 ];then
	echo "Mise à jour, compilation et installation de x264"
	echo "Mise à jour, compilation et installation de x264" 2>> $LOG >> $LOG
	debian_x264_update || error "Sorry something went wrong, please check the $LOG file." &
else 
	echo "Téléchargement, compilation et installation de x264"
	echo "Téléchargement, compilation et installation de x264" 2>> $LOG >> $LOG
	debian_x264_install || error "Sorry something went wrong, please check the $LOG file." &
fi
PID=$!
#this is a simple progress indicator
while ps |grep $PID &>/dev/null; do
	echo -n "."
	echo -en "\b-"
	sleep 1
	echo -en "\b\\"
	sleep 1
	echo -en "\b|"
	sleep 1
	echo -en "\b/"
	sleep 1
done

echo -e "\bInstallation de x264 terminée"
echo
echo "
############################################
#         Installation de FFMpeg           #
############################################
"
if [ -d "$INSTALL"/ffmpeg/.svn ];then
	echo "Mise à jour, compilation et installation de FFMpeg"
	echo "Mise à jour, compilation et installation de FFMpeg" 2>> $LOG >> $LOG
	debian_ffmpeg_update || error "Sorry something went wrong, please check the $LOG file." &
else 
	echo "Téléchargement, compilation et installation de FFMpeg"
	echo "Téléchargement, compilation et installation de FFMpeg" 2>> $LOG >> $LOG
	debian_ffmpeg_install || error "Sorry something went wrong, please check the $LOG file." &
fi
PID=$!
#this is a simple progress indicator
while ps |grep $PID &>/dev/null; do
	echo -n "."
	echo -en "\b-"
	sleep 1
	echo -en "\b\\"
	sleep 1
	echo -en "\b|"
	sleep 1
	echo -en "\b/"
	sleep 1
done

echo -e "\bInstallation de FFMpeg terminée"
echo
echo "
############################################
#      Installation de FFMpeg2Theora       #
############################################
"
if [ -d "$INSTALL"/ffmpeg2theora/.svn ];then
	echo "Mise à jour, compilation et installation de ffmpeg2theora"
	echo "Mise à jour, compilation et installation de ffmpeg2theora" 2>> $LOG >> $LOG
	debian_ffmpeg2theora_update || error "Sorry something went wrong, please check the $LOG file." &
else 
	echo "Téléchargement, compilation et installation de ffmpeg2theora"
	echo "Téléchargement, compilation et installation de ffmpeg2theora" 2>> $LOG >> $LOG
	debian_ffmpeg2theora_install || error "Sorry something went wrong, please check the $LOG file." &
fi
PID=$!
#this is a simple progress indicator
while ps |grep $PID &>/dev/null; do
	echo -n "."
	echo -en "\b-"
	sleep 1
	echo -en "\b\\"
	sleep 1
	echo -en "\b|"
	sleep 1
	echo -en "\b/"
	sleep 1
done

echo -e "\bInstallation de ffmpeg2theora terminée"

echo
echo "
############################################
#       Installation de FFMpeg-php         #
############################################
"
if [ -d "$INSTALL"/ffmpeg-php ];then
	echo "Mise à jour, compilation et installation de ffmpeg-svn"
	echo "Mise à jour, compilation et installation de ffmpeg-svn" 2>> $LOG >> $LOG
	debian_ffmpeg_php_update || error "Sorry something went wrong, please check the $LOG file." &
else 
	echo "Téléchargement, compilation et installation de FFMpeg-svn"
	echo "Téléchargement, compilation et installation de FFMpeg-svn" 2>> $LOG >> $LOG
	debian_ffmpeg_php_install || error "Sorry something went wrong, please check the $LOG file." &
fi
PID=$!
#this is a simple progress indicator
while ps |grep $PID &>/dev/null; do
	echo -n "."
	echo -en "\b-"
	sleep 1
	echo -en "\b\\"
	sleep 1
	echo -en "\b|"
	sleep 1
	echo -en "\b/"
	sleep 1
done

echo -e "\bInstallation de FFMpeg-php terminée"

# check that the default place to download to and log file location is ok
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
		echo -e "\bCréation des liens symboliques des binaires pour AlternC terminée"
	fi
fi

echo "
############################################
#    Installation de SPIP et MediaSPIP     #
############################################
"
mediaspip_install

echo
echo "That's it, all done."
echo "exiting now, bye."

exit 