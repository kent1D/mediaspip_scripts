#!/bin/bash
#
# mediaspip_install
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

MESSAGEAIDE="EXPLICATIONS :

Ce script installera toutes les dépendances logicielles requises pour l'installation de 
mediaSPIP.

Il installera ensuite le logiciels SPIP (http://www.spip.net) ainsi que les extensions 
nécessaires dans le répertoire d'installation spécifié.
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
SPIP_SVN="svn://trac.rezo.net/spip/branches/spip-2.1"

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
		--cpus|-c) NO_OF_CPUCORES="${2}"
		shift;;
		--spip|-s) SPIP="${2}"
		shift;;
		--spip_version|-s_v) SPIP_VERSION="${2}"
		shift;;
		--spip_svn|-s_svn) SPIP_VERSION="${2}"
		shift;;
	esac
	shift
done

# On inclut le fichier de fonctions
. ./mediaspip_functions.sh

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
			echo "FFmpeg déja à jour"
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
echo "Le script démarre" > $LOG
echo "Installation des dépendances logicielles"
echo "Installation des dépendances logicielles" 2>> $LOG >> $LOG
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

echo -e "\bIntallation de FFMpeg-php terminée"

# check that the default place to download to and log file location is ok
if [ -d /var/alterc/exec.usr ]; then
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
		echo -e "\bCréation des liens symboliques des binaires terminée"
	fi
fi

# Installation de mediaSPIP
if [ ! -d $SPIP/mediaspip ]; then
	echo "Téléchargement de SPIP"
	cd $SPIP
	svn co $SPIP_SVN mediaspip 2>> $LOG >> $LOG
else 
	echo "Mise à jour de SPIP"
	cd $SPIP/mediaspip
	svn up 2>> $LOG >> $LOG
fi

REVISIONSPIP=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
echo "SPIP est installé à la révision $REVISIONSPIP"

echo
echo "Installation des extensions de mediaSPIP"

cd $SPIP/mediaspip/extensions/

if [ ! -d afficher_objets ]; then
	echo "Téléchargement du plugin Afficher Objets"
	svn co svn://zone.spip.org/spip-zone/_plugins_/afficher_objets  2>> $LOG >> $LOG
fi
if [ ! -d ajaxforms ]; then
	echo "Téléchargement du plugin ajaxforms"
	svn co svn://zone.spip.org/spip-zone/_plugins_/ajaxforms 2>> $LOG >> $LOG
fi
if [ ! -d auteurs_syndic ]; then
	echo "Téléchargement du plugin auteurs_syndic"
	svn co svn://zone.spip.org/spip-zone/_plugins_/auteurs_syndic 2>> $LOG >> $LOG
fi
if [ ! -d cfg2_compat ]; then
	echo "Téléchargement du plugin cfg2_compat"
	svn co svn://zone.spip.org/spip-zone/_plugins_/cfg2/extensions/compat cfg2_compat 2>> $LOG >> $LOG
fi
if [ ! -d cfg2_core ]; then
	echo "Téléchargement du plugin cfg2_core"
	svn co svn://zone.spip.org/spip-zone/_plugins_/cfg2/core cfg2_core 2>> $LOG >> $LOG
fi
if [ ! -d cfg2_interface ]; then
	echo "Téléchargement du plugin cfg2_interface"
	svn co svn://zone.spip.org/spip-zone/_plugins_/cfg2/extensions/interface cfg2_interface 2>> $LOG >> $LOG
fi
if [ ! -d contact ]; then
	echo "Téléchargement du plugin contact"
	svn co svn://zone.spip.org/spip-zone/_plugins_/contact  2>> $LOG >> $LOG
fi
if [ ! -d crayons ]; then
	echo "Téléchargement du plugin crayons"
	svn co svn://zone.spip.org/spip-zone/_plugins_/crayons  2>> $LOG >> $LOG
fi
if [ ! -d diogene ]; then
	echo "Téléchargement du plugin diogene"
	svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene  2>> $LOG >> $LOG
fi
if [ ! -d diogene_gerer_auteurs ]; then
	echo "Téléchargement du plugin diogene_gerer_auteurs"
	svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_gerer_auteurs  2>> $LOG >> $LOG
fi
if [ ! -d diogene_licence ]; then
	echo "Téléchargement du plugin diogene_licence"
	svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_licence  2>> $LOG >> $LOG
fi
if [ ! -d diogene_spipicious ]; then
	echo "Téléchargement du plugin diogene_spipicious"
	svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_spipicious  2>> $LOG >> $LOG
fi
if [ ! -d emballe_medias ]; then
	echo "Téléchargement du plugin emballe_medias"
	svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/import_video/emballe_medias  2>> $LOG >> $LOG
fi
if [ ! -d emballe_medias_spipmotion ]; then
	echo "Téléchargement du plugin emballe_medias_spipmotion"
	svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/import_video/emballe_medias_spipmotion  2>> $LOG >> $LOG
fi
if [ ! -d facteur ]; then
	echo "Téléchargement du plugin facteur"
	svn co svn://zone.spip.org/spip-zone/_plugins_/facteur  2>> $LOG >> $LOG
fi
if [ ! -d fonctions_images ]; then
	echo "Téléchargement du plugin fonctions_images"
	svn co svn://zone.spip.org/spip-zone/_plugins_/fonctions_images  2>> $LOG >> $LOG
fi
if [ ! -d forum ]; then
	echo "Téléchargement du plugin forum"
	svn co svn://zone.spip.org/spip-zone/_core_/branches/spip-2.1/plugins/forum  2>> $LOG >> $LOG
fi
if [ ! -d getID3 ]; then
	echo "Téléchargement du plugin getID3"
	svn co svn://zone.spip.org/spip-zone/_plugins_/getID3 2>> $LOG >> $LOG
fi
if [ ! -d html5 ]; then
	echo "Téléchargement du plugin html5"
	svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/html5 2>> $LOG >> $LOG
fi
if [ ! -d job_queue ]; then
	echo "Téléchargement du plugin job_queue"
	svn co svn://zone.spip.org/spip-zone/_plugins_/job_queue 2>> $LOG >> $LOG
fi
if [ ! -d jquery_ui ]; then
	echo "Téléchargement du plugin jquery_ui"
	svn co svn://zone.spip.org/spip-zone/_plugins_/jquery_ui 2>> $LOG >> $LOG
fi
if [ ! -d licence ]; then
	echo "Téléchargement du plugin licence"
	svn co svn://zone.spip.org/spip-zone/_plugins_/licence 2>> $LOG >> $LOG
fi
if [ ! -d mediaspip_config ]; then
	echo "Téléchargement du plugin mediaspip_config"
	svn co http://svn.aires-de-confluxence.info/svn/squelettes_spip/mediaspip_config 2>> $LOG >> $LOG
fi
if [ ! -d mediaspip_core ]; then
	echo "Téléchargement du plugin mediaspip_core"
	svn co http://svn.aires-de-confluxence.info/svn/MediaSPIP/plugins/mediaspip_core 2>> $LOG >> $LOG
fi
if [ ! -d mediaspip_init ]; then
	echo "Téléchargement du plugin mediaspip_init"
	svn co http://svn.aires-de-confluxence.info/svn/MediaSPIP/plugins/mediaspip_init 2>> $LOG >> $LOG
fi
if [ ! -d menus ]; then
	echo "Téléchargement du plugin menus"
	svn co svn://zone.spip.org/spip-zone/_plugins_/menus 2>> $LOG >> $LOG
fi
if [ ! -d nospam ]; then
	echo "Téléchargement du plugin nospam"
	svn co svn://zone.spip.org/spip-zone/_plugins_/nospam 2>> $LOG >> $LOG
fi
if [ ! -d nuage ]; then
	echo "Téléchargement du plugin nuage"
	svn co svn://zone.spip.org/spip-zone/_plugins_/nuage 2>> $LOG >> $LOG
fi
if [ ! -d palette ]; then
	echo "Téléchargement du plugin palette"
	svn co svn://zone.spip.org/spip-zone/_plugins_/palette 2>> $LOG >> $LOG
fi
if [ ! -d pcltar ]; then
	echo "Téléchargement du plugin pcltar"
	svn co svn://zone.spip.org/spip-zone/_plugins_/pcltar 2>> $LOG >> $LOG
fi
if [ ! -d polyhierarchie ]; then
	echo "Téléchargement du plugin polyhierarchie"
	svn co svn://zone.spip.org/spip-zone/_plugins_/polyhierarchie 2>> $LOG >> $LOG
fi
if [ ! -d saisies ]; then
	echo "Téléchargement du plugin saisies"
	svn co svn://zone.spip.org/spip-zone/_plugins_/saisies 2>> $LOG >> $LOG
fi
if [ ! -d saveauto ]; then
	echo "Téléchargement du plugin saveauto"
	svn co svn://zone.spip.org/spip-zone/_plugins_/saveauto/2.1 saveauto 2>> $LOG >> $LOG
fi
if [ ! -d selecteur_generique ]; then
	echo "Téléchargement du plugin selecteur_generique"
	svn co svn://zone.spip.org/spip-zone/_plugins_/selecteur_generique 2>> $LOG >> $LOG
fi
if [ ! -d spip-bonux-2 ]; then
	echo "Téléchargement du plugin spip-bonux-2"
	svn co svn://zone.spip.org/spip-zone/_plugins_/spip-bonux-2 2>> $LOG >> $LOG
fi
if [ ! -d spipicious_jquery ]; then
	echo "Téléchargement du plugin spipicious_jquery"
	svn co svn://zone.spip.org/spip-zone/_plugins_/spipicious_jquery 2>> $LOG >> $LOG
fi
if [ ! -d spipmotion ]; then
	echo "Téléchargement du plugin spipmotion"
	svn co svn://zone.spip.org/spip-zone/_plugins_/spipmotion 2>> $LOG >> $LOG
fi
if [ ! -d step ]; then
	echo "Téléchargement du plugin step"
	svn co svn://zone.spip.org/spip-zone/_plugins_/step 2>> $LOG >> $LOG
fi
if [ ! -d swfupload ]; then
	echo "Téléchargement du plugin swfupload"
	svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/swfupload 2>> $LOG >> $LOG
fi
if [ ! -d zen-garden ]; then
	echo "Téléchargement du plugin zen-garden"
	svn co svn://zone.spip.org/spip-zone/_plugins_/zen-garden 2>> $LOG >> $LOG
fi
if [ ! -d zeroclipboard ]; then
	echo "Téléchargement du plugin zeroclipboard"
	svn co svn://zone.spip.org/spip-zone/_plugins_/zeroclipboard 2>> $LOG >> $LOG
fi
if [ ! -d zpip ]; then
	echo "Téléchargement du plugin zpip"
	svn co svn://zone.spip.org/spip-zone/_squelettes_/zpip 2>> $LOG >> $LOG
fi

cd $SPIP/mediaspip

echo "Mise à jour des extensions de MediaSPIP"
svn up extensions/* 2>> $LOG >> /dev/null

echo "Les fichiers de MediaSPIP sont installés"

echo
echo "That's it, all done."
echo "exiting now, bye."

exit 