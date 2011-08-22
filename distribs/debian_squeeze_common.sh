#!/bin/bash
#
# debian_squeeze_common
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.3.4
#
# Installation des dépendances de manière stable pour debian
#
# Mise à jour 
# Version 0.3.3 : upgrade de libvpx en 0.9.7-p1
# Version 0.3.4 : upgrade de MediaInfo en 0.7.48

VERSION_DEBIAN_COMMON=0.3.4

# Ce script lancé tout seul ne sert à rien
# On s'arrête dès son appel

case "$0" in
	*debian_squeeze_common.sh) 
	printf "
########################################
MediaSPIP Debian common functions v$VERSION_DEBIAN_COMMON
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

# Installation de flvtool2
debian_squeeze_flvtool_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	echo $(eval_gettext "Info debut flvtool2")
	echo $(eval_gettext "Info debut flvtool2") 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	svn checkout svn://rubyforge.org/var/svn/flvtool2/trunk flvtool2 2>> $LOG >> $LOG  || return 1
	cd flvtool2
	ruby setup.rb 2>> $LOG >> $LOG || return 1
	echo $(eval_gettext "End flvtool2")
	echo
}

# Installation de Lame
# http://lame.sourceforge.net/
debian_squeeze_lame_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	LAME=$(which lame)
	if [ ! -z "$LAME"  ];then
		LAMEVERSION=$(lame --version |awk '/^LAME/ { print $4 }')
	fi
	cd $SRC_INSTALL
	VERSION="3.98.4"
	if [ "$LAMEVERSION" = "$VERSION" ]; then
		echo $(eval_gettext 'Info a jour lame $VERSION')
		echo $(eval_gettext 'Info a jour lame $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/lame-3.98.4.tar.gz ]; then
			echo $(eval_gettext 'Info debut lame install $VERSION')
			echo $(eval_gettext 'Info debut lame install $VERSION') 2>> $LOG >> $LOG
			wget http://downloads.sourceforge.net/project/lame/lame/3.98.4/lame-3.98.4.tar.gz 2>> $LOG >> $LOG || return 1
			tar xvf lame-3.98.4.tar.gz 2>> $LOG >> $LOG
		else
			echo $(eval_gettext 'Info debut lame update $VERSION')
			echo $(eval_gettext 'Info debut lame update $VERSION') 2>> $LOG >> $LOG
		fi
		cd lame-3.98.4
		echo $(eval_gettext "Info compilation configure")
		./configure 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "Info compilation install")
		checkinstall --fstrans=no --install=yes --pkgname="libmp3lame-dev" --pkgversion="$VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "End lame")
	fi
	echo
}

# Installation de libopencore-amr
# http://opencore-amr.sourceforge.net/
debian_squeeze_libopencore_amr_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	LIBOPENCORE=$(pkg-config --modversion opencore-amrnb 2>> $LOG)
	cd $SRC_INSTALL
	VERSION="0.1.2"
	if [ "$LIBOPENCORE" = "$VERSION" ]; then
		echo $(eval_gettext 'Info a jour opencore $VERSION')
		echo $(eval_gettext 'Info a jour opencore $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/opencore-amr-0.1.2.tar.gz ];then
			echo $(eval_gettext 'Info debut opencore install $VERSION')
			echo $(eval_gettext 'Info debut opencore install $VERSION') 2>> $LOG >> $LOG
			wget http://transact.dl.sourceforge.net/project/opencore-amr/opencore-amr/0.1.2/opencore-amr-0.1.2.tar.gz 2>> $LOG >> $LOG || return 1
			tar xvf opencore-amr-0.1.2.tar.gz 2>> $LOG >> $LOG
		else
			echo $(eval_gettext 'Info debut opencore update $VERSION')
			echo $(eval_gettext 'Info debut opencore update $VERSION') 2>> $LOG >> $LOG
		fi
		cd opencore-amr-0.1.2
		echo $(eval_gettext "Info compilation configure")
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		./configure --enable-shared 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		checkinstall --fstrans=no --install=yes --pkgname="libopencore-amr" --pkgversion="$VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext "End opencore")
	fi
	echo
}

# Installation de libvpx
# http://code.google.com/p/webm/
debian_squeeze_libvpx_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip

	cd $SRC_INSTALL
	VERSION="0.9.7-p1"
	LIBVPX=$(dpkg --status libvpx 2>> $LOG |awk '/^Version/ { print $2 }') 2>> $LOG >> $LOG
	case "$LIBVPX" in
		*$VERSION*) 
			echo $(eval_gettext 'Info a jour libvpx $VERSION')
			echo $(eval_gettext 'Info a jour libvpx $VERSION') 2>> $LOG >> $LOG
			;;
		*)
			echo $(eval_gettext 'Info debut libvpx install $VERSION')
			echo $(eval_gettext 'Info debut libvpx install $VERSION') 2>> $LOG >> $LOG
			if [ ! -e "$SRC_INSTALL"/libvpx-v0.9.7-p1.tar.bz2 ];then
				wget http://webm.googlecode.com/files/libvpx-v0.9.7-p1.tar.bz2 2>> $LOG >> $LOG
				tar xvjf libvpx-v0.9.7-p1.tar.bz2 2>> $LOG >> $LOG
			elif [ ! -d "$SRC_INSTALL"/libvpx-v0.9.7-p1 ]; then
				tar xvjf libvpx-v0.9.7-p1.tar.bz2 2>> $LOG >> $LOG
			fi
			cd libvpx-v0.9.7-p1
			make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
			echo $(eval_gettext "Info compilation configure")
			./configure --enable-shared 2>> $LOG >> $LOG
			echo $(eval_gettext "Info compilation make")
			make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
			echo $(eval_gettext "Info compilation install")
			apt-get -y --force-yes remove libvpx 2>> $LOG >> $LOG
			checkinstall --fstrans=no --install=yes --pkgname="libvpx" --pkgversion="$VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG
			echo $(eval_gettext "End libvpx")
			;;
	esac
	echo
}

# Installation de libtheora
# http://www.theora.org/downloads/
debian_squeeze_libtheora_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	apt-get -y --force-yes install libogg-dev 2>> $LOG >> $LOG
	LIBTHEORAVERSION=$(pkg-config --modversion theora 2>> $LOG)
	cd $SRC_INSTALL
	VERSION="1.1.1"
	if [ "$LIBTHEORAVERSION" = "$VERSION" ]; then
		echo $(eval_gettext 'Info a jour libtheora $VERSION')
		echo $(eval_gettext 'Info a jour libtheora $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/libtheora-1.1.1.tar.gz ];then
			echo $(eval_gettext 'Info debut libtheora install $VERSION')
			echo $(eval_gettext 'Info debut libtheora install $VERSION') 2>> $LOG >> $LOG
			wget http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz 2>> $LOG >> $LOG
			tar xzvf libtheora-1.1.1.tar.gz 2>> $LOG >> $LOG
		else
			echo $(eval_gettext 'Info debut libtheora update $VERSION')
			echo $(eval_gettext 'Info debut libtheora update $VERSION') 2>> $LOG >> $LOG
		fi
		cd libtheora-1.1.1
		echo $(eval_gettext "Info compilation configure")
		./configure --enable-shared 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		checkinstall --fstrans=no --install=yes --pkgname=libtheora-dev --pkgversion "$VERSION+mediaspip" --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext "End libtheora")
	fi
	echo
}

# Installation de mediainfo
# http://mediainfo.sourceforge.net/fr
debian_squeeze_media_info_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	MEDIAINFO=$(which mediainfo)
	if [ ! -z "$MEDIAINFO" ]; then
		MEDIAINFOVERSION=$(mediainfo --Version |awk '/^MediaInfoLib/ { print $3 }') 2>> $LOG >> $LOG
	fi
	VERSION="0.7.48"
	if [ "$MEDIAINFOVERSION" = "v$VERSION" ]; then
		echo $(eval_gettext 'Info a jour mediainfo $VERSION')
		echo $(eval_gettext 'Info a jour mediainfo $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/MediaInfo_CLI_0.7.48_GNU_FromSource.tar.bz2 ];then
			echo $(eval_gettext 'Info debut mediainfo install $VERSION')
			echo $(eval_gettext 'Info debut mediainfo install $VERSION') 2>> $LOG >> $LOG
			cd $SRC_INSTALL
			wget http://downloads.sourceforge.net/mediainfo/MediaInfo_CLI_0.7.48_GNU_FromSource.tar.bz2 2>> $LOG >> $LOG || return 1
			tar -xvjf MediaInfo_CLI_0.7.48_GNU_FromSource.tar.bz2 2>> $LOG >> $LOG || return 1
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

# Installation de php-imagick via pecl
# On n'utilise pas la version des dépots officiels car trop ancienne
# et bugguée avec safe_mode php
# http://pecl.php.net/package/imagick
debian_squeeze_phpimagick_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
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
	echo
}

# Installation de diverses dépendances
# Pour Debian lenny
debian_squeeze_dep_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	
	DEBIANMULTIMEDIA=$(grep "debian-multimedia" /etc/apt/sources.list |grep squeeze) 2>> $LOG >> $LOG
	if [ -z "$DEBIANMULTIMEDIA" ];then
		echo $(eval_gettext 'Info apt debian-multimedia question auto')
		read -p "$QUESTION_VALID"
		[ "$REPLY" = "y" ] || [ "$REPLY" = "o" ] || [ -z "$REPLY" ] || die $(eval_gettext 'Erreur apt debian-multimedia')
			echo
			echo $(eval_gettext 'Info apt debian-multimedia copie')
			echo "deb http://www.debian-multimedia.org squeeze main non-free" >> /etc/apt/sources.list 2>> $LOG
			echo $(eval_gettext 'Info apt debian-multimedia installation cle')
			cd $SRC_INSTALL
			wget http://www.debian-multimedia.org/pool/main/d/debian-multimedia-keyring/debian-multimedia-keyring_2010.12.26_all.deb 2>> $LOG >> $LOG
			dpkg -i debian-multimedia-keyring_2010.12.26_all.deb 2>> $LOG >> $LOG
			rm debian-multimedia-keyring_2010.12.26_all.deb 2>> $LOG >> $LOG
			echo $(eval_gettext 'End debian-multimedia')
			echo
	fi
	echo $(eval_gettext "Info apt maj base")
	echo $(eval_gettext "Info apt maj base") 2>> $LOG >> $LOG
	apt-get -y --force-yes update 2>> $LOG >> $LOG || return 1
	echo $(eval_gettext "Info apt maj paquets")
	echo $(eval_gettext "Info apt maj paquets") 2>> $LOG >> $LOG
	apt-get -y --force-yes remove php5-imagick 2>> $LOG >> $LOG || return 1
	apt-get -y --force-yes install build-essential subversion git-core checkinstall libcxxtools-dev scons zlib1g-dev \
		apache2.2-common mysql-server php5-dev php5-mysql php-pear php5-curl php5-gd libmagick9-dev ruby yasm texi2html \
		libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev librtmp-dev libfaac-dev libfaad-dev libdirac-dev libgsm1-dev libopenjpeg-dev libxvidcore4-dev libschroedinger-dev libspeex-dev libvorbis-dev \
		flac mediainfo vorbis-tools xpdf \
		2>> $LOG >> $LOG || return 1
	echo
	
	verif_svn_protocole || return 1
	
	#debian_squeeze_lame_install || return 1
	
	#debian_squeeze_libopencore_amr_install || return 1
	
	#debian_squeeze_libtheora_install || return 1
	
	debian_squeeze_libvpx_install || return 1
	
	#debian_squeeze_rtmpdump_install || return 1
	
	debian_squeeze_flvtool_install || return 1
	
	debian_squeeze_media_info_install || return 1
	
	debian_squeeze_phpimagick_install || return 1
	
	cd $CURRENT
	return 0
}

# Préconfiguration basique d'Apache
debian_squeeze_apache_install ()
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
	echo
	
	echo $(eval_gettext "Info apache reload")
	echo $(eval_gettext "Info apache reload") 2>> $LOG >> $LOG
	/etc/init.d/apache2 force-reload 2>> $LOG >> $LOG || return 1
	
	echo
}

# Installation de x264
# http://www.videolan.org/developers/x264.html
debian_squeeze_x264_install ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	cd "$SRC_INSTALL"
	
	# Si on a déjà les sources, on ne fait que les mettre à jour
	if [ -d $SRC_INSTALL/x264/.git ];then
		echo $(eval_gettext "Info debut x264 update")
		echo
		echo $(eval_gettext "Info debut x264 update") 2>> $LOG >> $LOG
		cd $SRC_INSTALL/x264
		git pull 2>> $LOG >> $LOG || return 1
		NEWREVISION=$(git_log ./ | awk '/^== Short Revision:/ { print $4 }') 2>> $LOG >> $LOG
	# Sinon on les récupère
	else
		echo $(eval_gettext "Info debut x264 install")
		echo
		echo $(eval_gettext "Info debut x264 install") 2>> $LOG >> $LOG
		git clone git://git.videolan.org/x264.git 2>> $LOG >> $LOG || return 1
		cd $SRC_INSTALL/x264
		NEWREVISION=$(git_log ./ | awk '/^== Short Revision:/ { print $4 }') 2>> $LOG >> $LOG
	fi
	
	REVISION=$(pkg-config --modversion x264  2>> $LOG | awk '{ print $2 }')
	if [ "$REVISION" = "$NEWREVISION" ]; then
		echo $(eval_gettext "Info a jour x264")
		echo $(eval_gettext "Info a jour x264") 2>> $LOG >> $LOG
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

# Installation de ffmpeg-php
# http://ffmpeg-php.sourceforge.net/
debian_squeeze_ffmpeg_php_install ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	apt-get -y --force-yes remove php5-ffmpeg 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	svn co https://ffmpeg-php.svn.sourceforge.net/svnroot/ffmpeg-php/trunk ffmpeg-php 2>> $LOG >> $LOG
	cd ffmpeg-php/ffmpeg-php
	phpize 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
	echo $(eval_gettext "Info compilation configure")
	./configure 2>> $LOG >> $LOG || return 1
	echo $(eval_gettext "Info compilation make")
	make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || return 1
	make install 2>> $LOG >> $LOG || return 1
	echo 'extension=ffmpeg.so' > /etc/php5/conf.d/ffmpeg.ini
	/etc/init.d/apache2 force-reload 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')
	echo
	echo $(eval_gettext 'Info ffmpeg-php revision $REVISION')
}

# Mise à jour de ffmpeg-php
# http://ffmpeg-php.sourceforge.net/
debian_squeeze_ffmpeg_php_update ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	cd "$SRC_INSTALL"/ffmpeg-php/ffmpeg-php
	OLDREVISION=$(svnversion)
	svn up 2>> $LOG >> $LOG
	REVISION=$(svnversion)
	if [ "$OLDREVISION" = "$REVISION" ];then
		echo
		echo $(eval_gettext "Info a jour ffmpeg-php")
		echo $(eval_gettext "Info a jour ffmpeg-php") 2>> $LOG >> $LOG
	else
		phpize 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation configure")
		./configure 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		make install 2>> $LOG >> $LOG || return 1
		echo 'extension=ffmpeg.so' > /etc/php5/conf.d/ffmpeg.ini
		/etc/init.d/apache2 force-reload 2>> $LOG >> $LOG
	fi
	echo
	echo $(eval_gettext 'Info ffmpeg-php revision $REVISION')
}