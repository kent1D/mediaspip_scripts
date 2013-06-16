#!/bin/bash
#
# ubuntu_lucid
# © 2011-2012 - kent1 (kent1@arscenic.info)
# Version 0.3.15
#
# Installation des dépendances de manière stable pour Ubuntu lucid
#
# Mise à jour 
# Version 0.3.3 : upgrade de libvpx en 0.9.7-p1
# Version 0.3.4 : upgrade de MediaInfo en 0.7.48
# Version 0.3.5 : 
# -* ajout de libboost-dev à apt-get pour installer flvtool++
# -* installation de flvtool++ en version 1.2.1
# Version 0.3.6 : upgrade de MediaInfo en 0.7.49
# Version 0.3.7 : upgrade de MediaInfo en 0.7.50
# Version 0.3.8 : upgrade de MediaInfo en 0.7.51
# Version 0.3.9 : changement de l'URL de flvtool++
# Version 0.3.10 : upgrade de MediaInfo en 0.7.52
# Version 0.3.11 : upgrade de MediaInfo en 0.7.53
# Version 0.3.12 : suppression de ffmpeg-php
# Version 0.3.13 : installation d'une version moderne de yasm pour avoir x264
# Version 0.3.14 : 
# -* upgrade de MediaInfo en 0.7.57
# -* upgrade de libvpx en 1.1.0
# Version 0.3.15 : upgrade de MediaInfo en 0.7.58
# Version 0.4.0 : 
# -* on n'installe plus flvtool2
# -* installation de libopus 1.0.1
# -* installation de libmodplug
# -* installation de libtwolame
# -* on merge le fichier _stable : on installe ffmpeg depuis ce fichier
# - on compile FFmpeg en version 1.0 avec :
# -* libass
# -* libopus
# -* libmodplug
# -* libtwolame
# -* upgrade de MediaInfo en 0.7.61

# Ce script lancé tout seul ne sert à rien
# On s'arrête dès son appel
case "$0" in
	*ubuntu_lucid.sh) 
	printf "
########################################
MediaSPIP Ubuntu functions
########################################\n\n"
	printf "This file is only usefull for its functions"
	tput setaf 1;
	printf "
This file doesn't work standalone.
Please have a look to mediaspip_install.sh\n\n"
	tput sgr0; 
	exit 1 
	shift;;
esac

# Installation de diverses dépendances
# Pour Ubuntu Lucid
ubuntu_lucid_dep_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	echo $(eval_gettext "Info apt maj base")
	echo $(eval_gettext "Info apt maj base") 2>> $LOG >> $LOG
	apt-get -y --force-yes update 2>> $LOG >> $LOG || return 1
	echo $(eval_gettext "Info apt maj paquets")
	echo $(eval_gettext "Info apt maj paquets") 2>> $LOG >> $LOG
	apt-get -y --force-yes remove php5-imagick 2>> $LOG >> $LOG || return 1
	export DEBIAN_FRONTEND=noninteractive
	apt-get -q -y --force-yes install build-essential curl subversion git-core checkinstall libcxxtools-dev scons libboost-dev zlib1g-dev unzip \
		apache2 mysql-server php5-dev php-pear php5-curl php5-mysql php5-gd libapache2-mod-php5 libmagick9-dev texi2html \
		libfaac-dev libfaad-dev libmodplug-dev libgsm1-dev libopenjpeg-dev libxvidcore-dev libtheora-dev libschroedinger-dev libspeex-dev libvorbis-dev libass-dev libtwolame-dev \
		flac vorbis-tools xpdf poppler-utils catdoc imagemagick pngnq optipng libjpeg-progs \
		2>> $LOG >> $LOG || return 1
	apt-get clean 2>> $LOG >> $LOG || return 1
	echo

	verif_svn_protocole || return 1
	
	ubuntu_lucid_yasm_install || return 1
	
	ubuntu_lucid_lame_install || return 1

	ubuntu_lucid_libopus_install || return 1
	
	ubuntu_lucid_libopencore_amr_install || return 1

	ubuntu_lucid_libvpx_install || return 1

	ubuntu_lucid_rtmpdump_install || return 1
	
	flvtool_plus_install || return 1

	media_info_install || return 1

	ubuntu_lucid_phpimagick_install || return 1
	
	cd $CURRENT
	return 0
}

# Installation de yasm
# http://yasm.tortall.net/
ubuntu_lucid_yasm_install ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	SOFT="yasm"
	cd "$SRC_INSTALL"
	
	VERSION="1.2.0"
	if [ -x $(which yasm) ];then
		YASMVERSION=$($(which yasm) --version |awk '/^yasm/ { print $2 }') 2>> $LOG >> $LOG
	fi
	if [ "$YASMVERSION" = "$VERSION" ];then
		echo $(eval_gettext 'Info a jour $SOFT $VERSION')
		echo $(eval_gettext 'Info a jour $SOFT $VERSION') 2>> $LOG >> $LOG
	else
		echo $(eval_gettext 'Info debut $SOFT install')
		echo $(eval_gettext 'Info debut $SOFT install') 2>> $LOG >> $LOG
		if [ ! -e "$SRC_INSTALL"/yasm-1.2.0.tar.gz ];then
			wget http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz 2>> $LOG >> $LOG || return 1
			tar xvzf yasm-1.2.0.tar.gz 2>> $LOG >> $LOG || return 1
		fi
		cd yasm-1.2.0
		echo $(eval_gettext "Info compilation configure")
		./configure 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "Info compilation install")
		checkinstall --pkgname=yasm --pkgversion "$VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext 'End $SOFT')
	fi
	echo
}

# Installation de Lame
# http://lame.sourceforge.net/
ubuntu_lucid_lame_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	SOFT="lame"
	LAME=$(which lame)
	if [ ! -z "$LAME"  ];then
		LAMEVERSION=$(lame --version |awk '/^LAME/ { print $4 }')
	fi
	cd $SRC_INSTALL
	VERSION="3.98.4"
	if [ "$LAMEVERSION" = "$VERSION" ]; then
		echo $(eval_gettext 'Info a jour $SOFT $VERSION')
		echo $(eval_gettext 'Info a jour $SOFT $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/lame-3.98.4.tar.gz ]; then
			echo $(eval_gettext 'Info debut $SOFT install $VERSION')
			echo $(eval_gettext 'Info debut $SOFT install $VERSION') 2>> $LOG >> $LOG
			wget http://downloads.sourceforge.net/project/lame/lame/3.98.4/lame-3.98.4.tar.gz 2>> $LOG >> $LOG || return 1
			tar xvf lame-3.98.4.tar.gz 2>> $LOG >> $LOG
		else
			echo $(eval_gettext 'Info debut $SOFT update $VERSION')
			echo $(eval_gettext 'Info debut $SOFT update $VERSION') 2>> $LOG >> $LOG
		fi
		cd lame-3.98.4
		echo $(eval_gettext "Info compilation configure")
		./configure 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "Info compilation install")
		checkinstall --fstrans=no --install=yes --pkgname="libmp3lame-dev" --pkgversion="$VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext 'End $SOFT')
	fi
	echo
}

# Installation de libopencore-amr
# http://opencore-amr.sourceforge.net/
ubuntu_lucid_libopencore_amr_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	LIBOPENCORE=$(pkg-config --modversion opencore-amrnb 2>> $LOG)
	SOFT="libopencore-amr"
	cd $SRC_INSTALL
	VERSION="0.1.2"
	if [ "$LIBOPENCORE" = "$VERSION" ]; then
		echo $(eval_gettext 'Info a jour $SOFT $VERSION')
		echo $(eval_gettext 'Info a jour $SOFT $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/opencore-amr-0.1.2.tar.gz ];then
			echo $(eval_gettext 'Info debut $SOFT install $VERSION')
			echo $(eval_gettext 'Info debut $SOFT install $VERSION') 2>> $LOG >> $LOG
			wget http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/0.1.2/opencore-amr-0.1.2.tar.gz 2>> $LOG >> $LOG || return 1
			tar xvf opencore-amr-0.1.2.tar.gz 2>> $LOG >> $LOG
		else
			echo $(eval_gettext 'Info debut $SOFT update $VERSION')
			echo $(eval_gettext 'Info debut $SOFT update $VERSION') 2>> $LOG >> $LOG
		fi
		cd opencore-amr-0.1.2
		echo $(eval_gettext "Info compilation configure")
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		./configure --enable-shared 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		checkinstall --fstrans=no --install=yes --pkgname="libopencore-amr" --pkgversion="$VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext 'End $SOFT')
	fi
	echo
}

# Installation de libvpx
# http://code.google.com/p/webm/
ubuntu_lucid_libvpx_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	SOFT="libvpx"
	cd $SRC_INSTALL
	VERSION="1.1.0"
	LIBVPX=$(dpkg --status libvpx 2>> $LOG |awk '/^Version/ { print $2 }') 2>> $LOG >> $LOG
	case "$LIBVPX" in
		*$VERSION*)
			echo $(eval_gettext 'Info a jour $SOFT $VERSION')
			echo $(eval_gettext 'Info a jour $SOFT $VERSION') 2>> $LOG >> $LOG
			;;
		*)
			echo $(eval_gettext 'Info debut $SOFT install $VERSION')
			echo $(eval_gettext 'Info debut $SOFT install $VERSION') 2>> $LOG >> $LOG
			if [ ! -e "$SRC_INSTALL"/libvpx-v1.1.0.tar.bz2 ];then
				wget http://webm.googlecode.com/files/libvpx-v1.1.0.tar.bz2 2>> $LOG >> $LOG
				tar xvjf libvpx-v1.1.0.tar.bz2 2>> $LOG >> $LOG
			elif [ ! -d "$SRC_INSTALL"/libvpx-v1.1.0 ]; then
				tar xvjf libvpx-v1.1.0.tar.bz2 2>> $LOG >> $LOG
			fi
			cd libvpx-v1.1.0
			make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
			echo $(eval_gettext "Info compilation configure")
			./configure --enable-shared 2>> $LOG >> $LOG
			echo $(eval_gettext "Info compilation make")
			make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
			echo $(eval_gettext "Info compilation install")
			apt-get -y --force-yes remove libvpx 2>> $LOG >> $LOG
			checkinstall --fstrans=no --install=yes --pkgname="libvpx" --pkgversion="$VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG
			echo $(eval_gettext 'End $SOFT')
			;;
	esac
	ldconfig
	echo
}

# Installation de libopus
# http://www.opus-codec.org
ubuntu_lucid_libopus_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	LIBOPUSVERSION=$(pkg-config --modversion opus 2>> $LOG)
	SOFT="libopus"
	cd $SRC_INSTALL
	VERSION="$LIBOPUS_VERSION"
	if [ "$LIBOPUSVERSION" = "$VERSION" ]; then
		echo $(eval_gettext 'Info a jour $SOFT $VERSION')
		echo $(eval_gettext 'Info a jour $SOFT $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/$LIBOPUS_FICHIER ];then
			echo $(eval_gettext 'Info debut $SOFT install $VERSION')
			echo $(eval_gettext 'Info debut $SOFT install $VERSION') 2>> $LOG >> $LOG
			wget $LIBOPUS_URL 2>> $LOG >> $LOG
			tar xvzf $LIBOPUS_FICHIER  2>> $LOG >> $LOG
		else
			echo $(eval_gettext 'Info debut $SOFT update $VERSION')
			echo $(eval_gettext 'Info debut $SOFT update $VERSION') 2>> $LOG >> $LOG
		fi
		cd $LIBOPUS_PATH
		echo $(eval_gettext "Info compilation configure")
		./configure 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		checkinstall --fstrans=no --install=yes --pkgname=libopus-dev --pkgversion "$VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext 'End $SOFT')
	fi
	echo
}

ubuntu_lucid_rtmpdump_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	SOFT="rtmpdump"
	apt-get -y --force-yes install libssl-dev 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	
	VERSION="2.3"
	if [ -x $(which rtmpdump) ];then
		RTMPDUMPVERSION=$(pkg-config --modversion librtmp) 2>> $LOG >> $LOG
	fi
	if [ "$RTMPDUMPVERSION" = "v$VERSION" ];then
		echo $(eval_gettext 'Info a jour $SOFT $VERSION')
		echo $(eval_gettext 'Info a jour $SOFT $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/rtmpdump-2.3.tgz ];then
			echo $(eval_gettext 'Info debut $SOFT install')
			echo $(eval_gettext 'Info debut $SOFT install') 2>> $LOG >> $LOG
			wget http://rtmpdump.mplayerhq.hu/download/rtmpdump-2.3.tgz 2>> $LOG >> $LOG || return 1
			tar xvzf rtmpdump-2.3.tgz 2>> $LOG >> $LOG || return 1
		fi
		cd rtmpdump-2.3
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "Info compilation install")
		checkinstall --pkgname=rtmpdump --pkgversion "$VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext 'End $SOFT')
	fi
	echo
}

# Installation de x264
# http://www.videolan.org/developers/x264.html
ubuntu_lucid_x264_install ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	SOFT="libx264"
	cd "$SRC_INSTALL"
	
	# Si on a déjà les sources, on ne fait que les mettre à jour
	if [ -d "$SRC_INSTALL"/x264/.git ];then
		echo $(eval_gettext 'Info debut $SOFT update')
		echo
		echo $(eval_gettext 'Info debut $SOFT update') 2>> $LOG >> $LOG
		cd $SRC_INSTALL/x264
		git pull 2>> $LOG >> $LOG || return 1
		NEWREVISION=$(git_log ./ | awk '/^== Short Revision:/ { print $4 }') 2>> $LOG >> $LOG
	# Sinon on les récupère
	else
		echo $(eval_gettext 'Info debut $SOFT install')
		echo
		echo $(eval_gettext 'Info debut $SOFT install') 2>> $LOG >> $LOG
		git clone git://git.videolan.org/x264.git 2>> $LOG >> $LOG || return 1
		cd $SRC_INSTALL/x264
		NEWREVISION=$(git_log ./ | awk '/^== Short Revision:/ { print $4 }') 2>> $LOG >> $LOG
	fi
	
	REVISION=$(pkg-config --modversion x264  2>> $LOG | awk '{ print $2 }')
	if [ "$REVISION" = "$NEWREVISION" ]; then
		echo $(eval_gettext "Info a jour $SOFT")
		echo $(eval_gettext "Info a jour $SOFT") 2>> $LOG >> $LOG
	else
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation configure")
		./configure --enable-shared 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || return 1
		apt-get -y --force-yes remove x264 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		checkinstall --pkgname=x264 --pkgversion "1:0.svn`date +%Y%m%d`+mediaspip" --backup=no --default 2>> $LOG >> $LOG || return 1
	fi
}

# Installation de FFMpeg
# http://www.ffmpeg.org
ubuntu_lucid_ffmpeg_install ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	SOFT="ffmpeg"
	cd $SRC_INSTALL
	if [  ! -e "$SRC_INSTALL"/$FFMPEG_FICHIER ];then
		echo $(eval_gettext 'Info debut $SOFT install')
		echo $(eval_gettext 'Info debut $SOFT install') 2>> $LOG >> $LOG
		echo
		wget $FFMPEG_URL 2>> $LOG >> $LOG
		tar xvjf $FFMPEG_FICHIER 2>> $LOG >> $LOG
	elif [ ! -d $FFMPEG_PATH ];then
		tar xvjf $FFMPEG_FICHIER 2>> $LOG >> $LOG
	fi

	if [ -x $(which ffmpeg) ];then
		VERSION_ACTUELLE=$(ffmpeg -version  2> /dev/null |grep ffmpeg -m 1 |awk '{print $2}')
	fi
	if [ "$VERSION_ACTUELLE" = "version" ];then
		VERSION_ACTUELLE=$(ffmpeg -version  2> /dev/null |grep ffmpeg -m 1 |awk '{print $3}')
	fi
	
	cd $SRC_INSTALL/$FFMPEG_PATH
	
	if [ "$FFMPEG_VERSION" = "$VERSION_ACTUELLE" ];then
		echo $(eval_gettext 'Info a jour $SOFT')
		echo $(eval_gettext 'Info a jour $SOFT') 2>> $LOG >> $LOG
	else
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation configure")
		./configure --disable-doc --disable-ffplay --disable-ffserver --enable-gpl --enable-version3 --enable-nonfree --enable-shared --enable-postproc --enable-pthreads --enable-libvpx \
			--enable-libfaac --enable-libmp3lame --enable-libxvid --disable-encoder=vorbis --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 \
			--enable-libopus --enable-libmodplug --enable-librtmp --enable-libspeex --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib --enable-libass --enable-libtwolame 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || return 1
		apt-get -y --force-yes remove ffmpeg  2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		checkinstall --pkgname=ffmpeg --pkgversion "3:`date +%Y%m%d`-$FFMPEG_VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG || return 1
		ldconfig
		cd tools
		cc qt-faststart.c -o qt-faststart 2>> $LOG >> $LOG
		cp qt-faststart /usr/local/bin
	fi
	echo
	echo $(eval_gettext 'Info $SOFT version $FFMPEG_VERSION')
}

# Installation de php-imagick via pecl
# On n'utilise pas la version des dépots officiels car trop ancienne
# et bugguée avec safe_mode php
# http://pecl.php.net/package/imagick
ubuntu_lucid_phpimagick_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	pecl channel-update pecl.php.net 2>> $LOG >> $LOG
	LATEST=$(pecl remote-info imagick |awk '/^Latest/ { print $2 }') 2>> $LOG >> $LOG
	ACTUEL=$(pecl remote-info imagick |awk '/^Installed/ { print $2 }') 2>> $LOG >> $LOG
	# Cas de l'installation
	if [ "$ACTUEL" = "-" ]; then
		echo $(eval_gettext "Info debut php-imagick install")
		echo $(eval_gettext "Info debut php-imagick install") 2>> $LOG >> $LOG
		echo autodetect | pecl install imagick 2>> $LOG >> $LOG
		echo $(eval_gettext "End php-imagick")
		echo $(eval_gettext "End php-imagick") 2>> $LOG >> $LOG
	# Cas où on a déjà installé la dernière version
	elif [ "$ACTUEL" = "$LATEST" ]; then
		echo $(eval_gettext "Info a jour php-imagick")
		echo $(eval_gettext "Info a jour php-imagick") 2>> $LOG >> $LOG
	# Cas de la mise à jour
	else
		echo $(eval_gettext "Info debut php-imagick update")
		echo $(eval_gettext "Info debut php-imagick update") 2>> $LOG >> $LOG
		pecl upgrade imagick 2>> $LOG >> $LOG
		echo $(eval_gettext "End php-imagick")
		echo $(eval_gettext "End php-imagick") 2>> $LOG >> $LOG
	fi
	# On crée la conf si inexistante
	if [ ! -e /etc/php5/apache2/conf.d/imagick.ini ];then
		echo "; configuration for php imagick module" > /etc/php5/apache2/conf.d/imagick.ini
		echo "extension=imagick.so" >> /etc/php5/apache2/conf.d/imagick.ini
		/etc/init.d/apache2 force-reload 2>> $LOG >> $LOG || return 1
	fi
	echo
}

# Préconfiguration basique d'Apache
ubuntu_lucid_apache_install ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	echo $(eval_gettext "Info apache mod headers")
	echo $(eval_gettext "Info apache mod headers") 2>> $LOG >> $LOG
	a2enmod headers 2>> $LOG >> $LOG || return 1
	echo
	
	echo $(eval_gettext "Info apache mod rewrite")
	echo $(eval_gettext "Info apache mod rewrite") 2>> $LOG >> $LOG
	a2enmod rewrite 2>> $LOG >> $LOG || return 1
	echo
	
	echo $(eval_gettext "Info apache mod deflate")
	echo $(eval_gettext "Info apache mod deflate") 2>> $LOG >> $LOG
	a2enmod deflate 2>> $LOG >> $LOG || return 1
	echo $(eval_gettext "Info apache mod deflate fichier")
	echo $(eval_gettext "Info apache mod deflate fichier") 2>> $LOG >> $LOG
	cp ./configs/apache/deflate.conf /etc/apache2/conf.d/ 2>> $LOG >> $LOG || return 1
	echo
	
	echo $(eval_gettext "Info apache mod expires")
	echo $(eval_gettext "Info apache mod expires") 2>> $LOG >> $LOG
	a2enmod expires 2>> $LOG >> $LOG || return 1
	echo $(eval_gettext "Info apache mod expires fichier")
	echo $(eval_gettext "Info apache mod expires fichier") 2>> $LOG >> $LOG
	cp ./configs/apache/expires.conf /etc/apache2/conf.d/ 2>> $LOG >> $LOG || return 1
	echo
	
	echo $(eval_gettext "Info apache mime fichier")
	echo $(eval_gettext "Info apache mime fichier") 2>> $LOG >> $LOG
	cp ./configs/apache/mediaspip_mime.conf /etc/apache2/conf.d/ 2>> $LOG >> $LOG || return 1
	echo
	
	echo $(eval_gettext 'Info php max_upload $PHP_UPLOAD_SIZE')
	echo "file_uploads = On" > /etc/php5/conf.d/mediaspip_upload.ini
	echo "upload_max_filesize = $PHP_UPLOAD_SIZE" >> /etc/php5/conf.d/mediaspip_upload.ini
	echo "post_max_size = $PHP_UPLOAD_SIZE" >> /etc/php5/conf.d/mediaspip_upload.ini
	echo "suhosin.get.max_value_length = 1024" >> /etc/php5/conf.d/mediaspip_upload.ini
	echo
	
	cp $CURRENT/configs/apache/vhosts/* /etc/apache2/sites-available/ 2>> $LOG >> $LOG
	
	echo $(eval_gettext "Info apache reload")
	echo $(eval_gettext "Info apache reload") 2>> $LOG >> $LOG
	/etc/init.d/apache2 force-reload 2>> $LOG >> $LOG || return 1
	echo
}