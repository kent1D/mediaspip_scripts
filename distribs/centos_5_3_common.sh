#!/bin/bash
#
# centos_5_3_common
# © 2011-2012 - kent1 (kent1@arscenic.info)
# Version 0.3.11
#
# Installation des dépendances de manière stable pour centos
#
# Mise à jour 
# Version 0.3.3 : upgrade de libvpx en 0.9.7-p1
# Version 0.3.4 : upgrade de MediaInfo en 0.7.48
# Version 0.3.5 : 
# -* ajout de libboost-dev à yum pour installer flvtool++
# -* installation de flvtool++ en version 1.2.1
# Version 0.3.6 : upgrade de MediaInfo en 0.7.49
# Version 0.3.7 : upgrade de MediaInfo en 0.7.50
# Version 0.3.8 : upgrade de MediaInfo en 0.7.51
# Version 0.3.9 : changement de l'URL de flvtool++
# Version 0.3.10 : upgrade de MediaInfo en 0.7.52
# Version 0.3.11 : upgrade de MediaInfo en 0.7.53

VERSION_CENTOS_COMMON=0.3.11

export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/lib/pkgconfig

# Ce script lancé tout seul ne sert à rien
# On s'arrête dès son appel
case "$0" in
	*centos_5_3_common.sh) 
	printf "
########################################
MediaSPIP Centos common functions v$VERSION_CENTOS_COMMON
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
centos_flvtool_install()
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


# Installation de flvtool++
centos_flvtool_plus_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	
	FLVTOOLPLUS=$(which flvtool++)
	if [ ! -z "$FLVTOOLPLUS" ]; then
		FLVTOOLPLUSVERSION=$(flvtool++ |awk '/^flvtool++/ { print $2 }') 2>> $LOG >> $LOG
	fi
	
	VERSION="1.2.1"
	if [ "$FLVTOOLPLUSVERSION" = "$VERSION" ]; then
		echo $(eval_gettext 'Info a jour flvtool++ $VERSION')
		echo $(eval_gettext 'Info a jour flvtool++ $VERSION') 2>> $LOG >> $LOG
	else
		echo $(eval_gettext "Info debut flvtool++")
		echo $(eval_gettext "Info debut flvtool++") 2>> $LOG >> $LOG
		cd $SRC_INSTALL
		if [ ! -d flvtool++-1.2.1 ];then
			mkdir flvtool++-1.2.1 2>> $LOG >> $LOG
		fi
		cd flvtool++-1.2.1
		if [ ! -e flvtool++-1.2.1.tar.gz ];then
			wget http://files.mediaspip.net/binaires/flvtool++-1.2.1.tar.gz 2>> $LOG >> $LOG  || return 1
		fi
		tar xvzf flvtool++-1.2.1.tar.gz 2>> $LOG >> $LOG
		scons 2>> $LOG >> $LOG
		cp flvtool++ /usr/local/bin
		echo $(eval_gettext "End flvtool++")
	fi
	echo
}

# Installation d'une version récente de scons
# Utilisée pour ffmpeg2theora
# http://www.scons.org/
centos_scons_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	
	cd $SRC_INSTALL
	VERSION="2.0.1"
	if [ ! -e "$SRC_INSTALL"/scons-2.0.1.tar.gz ]; then
		echo $(eval_gettext 'Info debut scons install $VERSION')
		wget http://downloads.sourceforge.net/project/scons/scons/2.0.1/scons-2.0.1.tar.gz	2>> $LOG >> $LOG || return 1
		tar xvf scons-2.0.1.tar.gz 2>> $LOG >> $LOG || return 1
	else
		echo $(eval_gettext 'Info debut scons update $VERSION')
	fi
	cd scons-2.0.1
	python setup.py install 2>> $LOG >> $LOG || return 1
	echo $(eval_gettext "End scons")
	echo
}

# Installation de Lame
# http://lame.sourceforge.net/
centos_lame_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	LAME=$(which lame 2>> /dev/null)
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
		make install 2>> $LOG >> $LOG || return 1
		#checkinstall --fstrans=no --install=yes --pkgname="libmp3lame-dev" --pkgversion="$VERSION+mediaspip" --type=rpm --backup=no --default 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "End lame")
	fi
	echo
}

# Installation de libopencore-amr
# http://opencore-amr.sourceforge.net/
centos_libopencore_amr_install()
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
		make install 2>> $LOG >> $LOG || return 1
		#checkinstall --fstrans=no --install=yes --pkgname="libopencore-amr" --pkgversion="$VERSION+mediaspip" --type=rpm --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext "End opencore")
	fi
	echo
}

# Installation de libvpx
# http://code.google.com/p/webm/
centos_libvpx_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip

	cd $SRC_INSTALL
	VERSION="0.9.7-p1"
	LIBVPX=$(rpm -qi libvpx 2>> $LOG |awk '/^Version/ { print $2 }') 2>> $LOG >> $LOG
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
			yum -y erase libvpx 2>> $LOG >> $LOG
			make install 2>> $LOG >> $LOG || return 1
			#checkinstall --fstrans=no --install=yes --pkgname="libvpx" --pkgversion="$VERSION+mediaspip" --backup=no --type=rpm --default 2>> $LOG >> $LOG
			echo $(eval_gettext "End libvpx")
			;;
		esac
	echo
}

# Installation de libtheora
# http://www.theora.org/downloads/
centos_libtheora_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	yum -y install libogg-devel 2>> $LOG >> $LOG
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
		make install 2>> $LOG >> $LOG || return 1
		#checkinstall --fstrans=no --install=yes --pkgname=libtheora-dev --pkgversion "$VERSION+mediaspip" --type=rpm --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext "End libtheora")
	fi
	echo
}

# Installation de mediainfo
# http://mediainfo.sourceforge.net/fr
centos_media_info_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	MEDIAINFO=$(which mediainfo 2>> $LOG)
	if [ ! -z "$MEDIAINFO" ]; then
		MEDIAINFOVERSION=$(mediainfo --Version |awk '/^MediaInfoLib/ { print $3 }') 2>> $LOG >> $LOG
	fi
	VERSION="0.7.53"
	if [ "$MEDIAINFOVERSION" = "v$VERSION" ]; then
		echo $(eval_gettext 'Info a jour mediainfo $VERSION')
		echo $(eval_gettext 'Info a jour mediainfo $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/MediaInfo_CLI_0.7.53_GNU_FromSource.tar.bz2 ];then
			echo $(eval_gettext 'Info debut mediainfo install $VERSION')
			echo $(eval_gettext 'Info debut mediainfo install $VERSION') 2>> $LOG >> $LOG
			cd $SRC_INSTALL
			wget http://downloads.sourceforge.net/mediainfo/MediaInfo_CLI_0.7.53_GNU_FromSource.tar.bz2 2>> $LOG >> $LOG || return 1
			tar -xvjf MediaInfo_CLI_0.7.53_GNU_FromSource.tar.bz2 2>> $LOG >> $LOG || return 1
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

# Installation du décodeur AAC
# http://www.audiocoding.com/
centos_faad_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	VERSION="2.7"
	SOFTWARE="faad"
	FAADVERSION=$(faad -h 2>&1 |awk '/Ahead Software MPEG-4 AAC/ { print $7 }')
	if [ "$FAADVERSION" = "V$VERSION" ]; then
		echo $(eval_gettext 'Info a jour $SOFTWARE $VERSION')
		echo $(eval_gettext 'Info a jour $SOFTWARE $VERSION') 2>> $LOG >> $LOG
	else
		cd $SRC_INSTALL
		if [ ! -e "$SRC_INSTALL"/faad2-2.7.tar.gz ];then
			echo $(eval_gettext 'Info debut faad install $VERSION')
			echo $(eval_gettext 'Info debut faad install $VERSION') 2>> $LOG >> $LOG
			wget http://downloads.sourceforge.net/faac/faad2-2.7.tar.gz 2>> $LOG >> $LOG ||return 1  
			tar zxf faad2-2.7.tar.gz 2>> $LOG >> $LOG ||return 1
		else
			if [ ! -d faad2-2.7 ];then
				tar zxf faad2-2.7.tar.gz 2>> $LOG >> $LOG ||return 1
			fi
			echo $(eval_gettext 'Info debut faad update $VERSION')
			echo $(eval_gettext 'Info debut faad update $VERSION') 2>> $LOG >> $LOG
		fi
		cd faad2-2.7
		autoreconf -vif 2>> $LOG >> $LOG ||return 1  
		./configure 2>> $LOG >> $LOG ||return 1 
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG ||return 1 
		make install  2>> $LOG >> $LOG ||return 1
		ldconfig
		echo $(eval_gettext "End faad")
	fi
	echo 
}

# Installation de l'encodeur AAC
# http://www.audiocoding.com/
centos_faac_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	VERSION="1.28"
	SOFTWARE="faac"
	FAACVERSION=$(faac --help 2>&1 |awk '/^FAAC/ { print $2 }')
	if [ "$FAACVERSION" = "$VERSION" ]; then
		echo $(eval_gettext 'Info a jour $SOFTWARE $VERSION')
		echo $(eval_gettext 'Info a jour $SOFTWARE $VERSION') 2>> $LOG >> $LOG
	else
		cd $SRC_INSTALL
		if [ ! -e "$SRC_INSTALL"/faac-1.28.tar.gz ];then
			echo $(eval_gettext 'Info debut faac install $VERSION')
			echo $(eval_gettext 'Info debut faac install $VERSION') 2>> $LOG >> $LOG
			wget http://downloads.sourceforge.net/faac/faac-1.28.tar.gz 2>> $LOG >> $LOG ||return 1 
			tar zxfv faac-1.28.tar.gz 2>> $LOG >> $LOG ||return 1
		else
			if [ ! -d faac-1.28 ];then
				tar zxfv faac-1.28.tar.gz 2>> $LOG >> $LOG ||return 1
			fi
			echo $(eval_gettext 'Info debut faac update $VERSION')
			echo $(eval_gettext 'Info debut faac update $VERSION') 2>> $LOG >> $LOG
		fi
		cd faac-1.28
		./bootstrap 2>> $LOG >> $LOG ||return 1 
		./configure 2>> $LOG >> $LOG ||return 1 
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG ||return 1 
		make install  2>> $LOG >> $LOG ||return 1
		ldconfig
		echo $(eval_gettext "End faac")
	fi
	echo
}

# Installation de xvidcore
# http://www.xvid.org/
centos_xvid_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	VERSION="1.2.2"
	SOFTWARE="xvidcore"
	if [ "$FAADVERSION" = "v$VERSION" ]; then
		echo $(eval_gettext 'Info a jour $SOFTWARE $VERSION')
		echo $(eval_gettext 'Info a jour $SOFTWARE $VERSION') 2>> $LOG >> $LOG
	else
		cd $SRC_INSTALL
		if [ ! -e "$SRC_INSTALL"/xvidcore-1.2.2.tar.gz ];then
			echo $(eval_gettext 'Info debut xvidcore install $VERSION')
			echo $(eval_gettext 'Info debut xvidcore install $VERSION') 2>> $LOG >> $LOG
			wget http://downloads.xvid.org/downloads/xvidcore-1.2.2.tar.gz 2>> $LOG >> $LOG ||return 1 
			tar zxfv xvidcore-1.2.2.tar.gz 2>> $LOG >> $LOG ||return 1
		else
			if [ ! -d xvidcore ];then
				tar zxfv xvidcore-1.2.2.tar.gz 2>> $LOG >> $LOG ||return 1
			fi
			echo $(eval_gettext 'Info debut xvidcore update $VERSION')
			echo $(eval_gettext 'Info debut xvidcore update $VERSION') 2>> $LOG >> $LOG
		fi
		cd xvidcore/build/generic 
		./configure 2>> $LOG >> $LOG ||return 1 
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG ||return 1 
		make install  2>> $LOG >> $LOG ||return 1
		echo $(eval_gettext "End xvid")
	fi
	echo
}

# Installation de php-imagick via pecl
# On n'utilise pas la version des dépots officiels car trop ancienne
# et bugguée avec safe_mode php
# http://pecl.php.net/package/imagick
centos_phpimagick_install()
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
# Pour Centos 5.3
centos_5_3_dep_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip

	EPEL=$(yum repolist |grep ^epel |grep enabled)
	if [ -z "$EPEL" ]; then
		echo $(eval_gettext "Info yum intallation epel")
		rm epel-release* 2>> $LOG >> $LOG
		wget http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm 2>> $LOG >> $LOG  
		rpm -Uvh epel-release-5*.rpm 2>> $LOG >> $LOG
	fi
	
	LDSO=$(cat /etc/ld.so.conf |grep '^/usr/local/lib')
	if [ -z "$LDSO" ];then
		echo "/usr/local/lib" >> /etc/ld.so.conf
		ldconfig
	fi
	echo $(eval_gettext "Info yum maj base")
	echo $(eval_gettext "Info yum maj base") 2>> $LOG >> $LOG
	yum -y check-update 2>> $LOG >> $LOG 
	echo $(eval_gettext "Info yum maj paquets")
	echo $(eval_gettext "Info yum maj paquets") 2>> $LOG >> $LOG
	yum -y erase php-pecl-imagick 2>> $LOG >> $LOG || return 1
	yum -y install rpm-build gcc-c++ subversion git libtool scons libboost-dev zlib-devel \
		httpd openssl-devel php-devel php-pear php-mysql php-pear-Net-Curl php-gd ImageMagick-devel ruby yasm texi2html \
		openjpeg-devel gsm-devel dirac-devel speex-devel libvorbis-devel \
		flac-devel vorbis-tools xpdf poppler-utils catdoc \
		2>> $LOG >> $LOG || return 1
	echo 
	
	verif_svn_protocole || return 1
	
	#if [ -x $(which scons 2>> $LOG) ];then
	#	SCONS_VERSION=$(scons -v | awk '/script:/ { print $2 }')
	#fi
	
	#if [ "$SCONS_VERSION" < "v1.2" ]; then
	#	centos_scons_install || return 1
	#fi 
	
	centos_lame_install || return 1
	
	centos_libopencore_amr_install || return 1
	
	centos_libtheora_install || return 1
	
	centos_libvpx_install || return 1
	
	centos_rtmpdump_install || return 1
	
	centos_flvtool_install || return 1
	
	centos_faad_install || return 1
	
	centos_faac_install || return 1
	
	centos_xvid_install || return 1
	
	centos_media_info_install || return 1
	
	centos_phpimagick_install || return 1
	
	cd $CURRENT
	return 0
}

# Préconfiguration basique d'Apache
centos_5_3_apache_install ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	echo $(eval_gettext "Info apache mod headers")
	echo $(eval_gettext "Info apache mod headers") 2>> $LOG >> $LOG 
	HEADERS=$(cat /etc/httpd/conf/httpd.conf |grep "^LoadModule headers_module")
	if [ -z "$HEADERS" ];then
		echo "LoadModule headers_module modules/mod_headers.so" >>  /etc/httpd/conf/httpd.conf || return 1
	fi
	echo
	
	echo $(eval_gettext "Info apache mod rewrite")
	echo $(eval_gettext "Info apache mod rewrite") 2>> $LOG >> $LOG
	REWRITE=$(cat /etc/httpd/conf/httpd.conf |grep "^LoadModule rewrite_module")
	if [ -z "$REWRITE" ];then
		echo "LoadModule rewrite_module modules/mod_rewrite.so" >>  /etc/httpd/conf/httpd.conf || return 1
	fi
	echo
	
	echo $(eval_gettext "Info apache mod deflate")
	echo $(eval_gettext "Info apache mod deflate") 2>> $LOG >> $LOG
	DEFLATE=$(cat /etc/httpd/conf/httpd.conf |grep "^LoadModule deflate_module")
	if [ -z "$DEFLATE" ];then
		echo "LoadModule deflate_module modules/mod_deflate.so" >>  /etc/httpd/conf/httpd.conf || return 1
	fi
	echo $(eval_gettext "Info apache mod deflate fichier")
	echo $(eval_gettext "Info apache mod deflate fichier") 2>> $LOG >> $LOG
	cp ./configs/apache/deflate.conf /etc/httpd/conf.d/ 2>> $LOG >> $LOG || return 1
	echo
	
	echo $(eval_gettext "Info apache mod expires")
	echo $(eval_gettext "Info apache mod expires") 2>> $LOG >> $LOG
	EXPIRES=$(cat /etc/httpd/conf/httpd.conf |grep "^LoadModule expires_module")
	if [ -z "$EXPIRES" ];then
		echo "LoadModule expires_module modules/mod_expires.so" >>  /etc/httpd/conf/httpd.conf || return 1
	fi
	echo $(eval_gettext "Info apache mod expires fichier")
	echo $(eval_gettext "Info apache mod expires fichier") 2>> $LOG >> $LOG
	cp ./configs/apache/expires.conf /etc/httpd/conf.d/ 2>> $LOG >> $LOG || return 1
	echo
	
	echo $(eval_gettext "Info apache mime fichier")
	echo $(eval_gettext "Info apache mime fichier") 2>> $LOG >> $LOG
	cp ./configs/apache/mediaspip_mime.conf /etc/httpd/conf.d/ 2>> $LOG >> $LOG || return 1
	echo
	
	echo $(eval_gettext 'Info php max_upload $PHP_UPLOAD_SIZE')
	echo "file_uploads = On" > /etc/php5/conf.d/mediaspip_upload.ini
	echo "upload_max_filesize = $PHP_UPLOAD_SIZE" >> /etc/php5/conf.d/mediaspip_upload.ini
	echo "post_max_size = $PHP_UPLOAD_SIZE" >> /etc/php5/conf.d/mediaspip_upload.ini
	echo
	
	echo $(eval_gettext "Info apache reload")
	echo $(eval_gettext "Info apache reload") 2>> $LOG >> $LOG
	service httpd graceful 2>> $LOG >> $LOG || return 1
	echo
}

# Installation de x264
# http://www.videolan.org/developers/x264.html
centos_5_3_x264_install ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	cd "$SRC_INSTALL"
	
	# Si on a déjà les sources, on ne fait que les mettre à jour
	if [ -d "$SRC_INSTALL"/x264/.git ];then
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
		yum -y erase x264* 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		#checkinstall --pkgname=x264 --pkgversion "1:0.svn`date +%Y%m%d`+mediaspip" --backup=no --type=rpm --default 2>> $LOG >> $LOG || return 1
		make install 2>> $LOG >> $LOG || return 1
	fi
}

# Installation de ffmpeg-php
# http://ffmpeg-php.sourceforge.net/
centos_5_3_ffmpeg_php_install ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	yum -y erase ffmpeg-php 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	svn co https://ffmpeg-php.svn.sourceforge.net/svnroot/ffmpeg-php/trunk ffmpeg-php 2>> $LOG >> $LOG || return 1
	cd ffmpeg-php/ffmpeg-php
	phpize 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG 
	make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
	echo $(eval_gettext "Info compilation configure")
	./configure 2>> $LOG >> $LOG || return 1
	echo $(eval_gettext "Info compilation make")
	make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || return 1
	make install 2>> $LOG >> $LOG || return 1
	echo 'extension=ffmpeg.so' > /etc/php.d/ffmpeg.ini 2>> $LOG >> $LOG || return 1
	service httpd graceful 2>> $LOG >> $LOG || return 1
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')
	echo
	echo $(eval_gettext 'Info ffmpeg-php revision $REVISION')
}

# Mise à jour de ffmpeg-php
# http://ffmpeg-php.sourceforge.net/
centos_5_3_ffmpeg_php_update ()
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
		phpize 2>> $LOG >> $LOG || return 1
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation configure")
		./configure 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		make install 2>> $LOG >> $LOG || return 1
		echo 'extension=ffmpeg.so' > /etc/php.d/ 2>> $LOG >> $LOG || return 1
		service httpd graceful 2>> $LOG >> $LOG || return 1
	fi
	echo
	echo $(eval_gettext 'Info ffmpeg-php revision $REVISION')
}