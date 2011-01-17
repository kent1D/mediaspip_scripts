#!/bin/bash
#
# mediaspip_functions
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.2
#
# Diverses fonctions permettant d'installer mediaSPIP

export TEXTDOMAINDIR=./locale
export TEXTDOMAIN=mediaspip

function isNumeric()
{
	echo "$@" | grep -q -v "[^0-9]"
}

in_array(){
    local i
    needle=$1
    shift 1
    # array() undefined
    [ -z "$1" ] && return 1
    for i in $*
    do
	    [ "$i" == "$needle" ] && return 0
    done
    return 1
}

function echo_erreur ()
{
	tput setaf 1;
	echo $@
	tput sgr0;
}

function echo_reussite ()
{
	tput setaf 2;
	echo $@
	tput sgr0;
}

#exit function
die ()
{
	echo_erreur $@ 
	exit 1
}

#error function
error ()
{
	echo_erreur $@
	echo
	kill "$$" 2>> $LOG >> $LOG	
	exit 1
}

function progress_indicator()
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
function git_log()
{
	cd $@
	# Show various information about this git directory
	if [ -d .git ]; then
	  echo "== Remote URL: `git remote -v`"
	
	  echo "== Remote Branches: "
	  git branch -r
	  echo
	
	  echo "== Local Branches:"
	  git branch
	  echo
	
	  echo "== Configuration (.git/config)"
	  cat .git/config
	  echo
	
	  echo "== Most Recent Commit"
	  git --no-pager log --max-count=1
	  echo
	else
	  echo "Not a git repository."
	fi
}

# Installation de flvtool2
debian_flvtool_install()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	echo $(eval_gettext "Info debut flvtool2")
	eval_gettext "Info debut flvtool2" 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	svn checkout svn://rubyforge.org/var/svn/flvtool2/trunk flvtool2 2>> $LOG >> $LOG
	cd flvtool2
	sudo ruby setup.rb 2>> $LOG >> $LOG
	echo $(eval_gettext "End flvtool2")
	echo
}

# Installation de Lame
debian_lame_install()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	LAMEVERSION=$(lame --version |awk '/^LAME/ { print $4 }')
	cd $SRC_INSTALL
	VERSION="3.98.4"
	if [ ! -e "$SRC_INSTALL"/lame-3.98.4.tar.gz ]; then
		echo $(eval_gettext 'Info debut lame install $VERSION')
		echo $(eval_gettext 'Info debut lame install $VERSION') 2>> $LOG >> $LOG
		wget http://downloads.sourceforge.net/project/lame/lame/3.98.4/lame-3.98.4.tar.gz 2>> $LOG >> $LOG
		tar xvf lame-3.98.4.tar.gz 2>> $LOG >> $LOG
		cd lame-3.98.4
		./configure 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		checkinstall --fstrans=no --install=yes --pkgname="libmp3lame" --pkgversion="3.98.4" --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext "End lame")
	elif [ "$LAMEVERSION" == "3.98.4" ]; then
		echo $(eval_gettext 'Info a jour lame $VERSION')
		echo $(eval_gettext 'Info a jour lame $VERSION') 2>> $LOG >> $LOG
	else
		echo $(eval_gettext 'Info debut lame update $VERSION')
		echo $(eval_gettext 'Info debut lame update $VERSION') 2>> $LOG >> $LOG
		cd lame-3.98.4
		./configure 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		checkinstall --fstrans=no --install=yes --pkgname="libmp3lame" --pkgversion="3.98.4" --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext "End lame")
	fi
	echo
}

# Installation de libopencore-amr
debian_libopencore_amr_install()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	LIBOPENCORE=$(pkg-config --modversion opencore-amrnb 2>> $LOG)
	cd $SRC_INSTALL
	VERSION="0.1.2"
	if [[ "$LIBOPENCORE" > "0.1.1" ]]; then
		echo $(eval_gettext 'Info a jour opencore $VERSION')
		echo $(eval_gettext 'Info a jour opencore $VERSION') 2>> $LOG >> $LOG
	elif [ ! -e "$SRC_INSTALL"/opencore-amr-0.1.2.tar.gz ];then
		echo $(eval_gettext 'Info debut opencore install $VERSION')
		echo $(eval_gettext 'Info debut opencore install $VERSION') 2>> $LOG >> $LOG
		wget http://transact.dl.sourceforge.net/project/opencore-amr/opencore-amr/0.1.2/opencore-amr-0.1.2.tar.gz 2>> $LOG >> $LOG
		tar xvf opencore-amr-0.1.2.tar.gz 2>> $LOG >> $LOG
		cd opencore-amr-0.1.2
		./configure --enable-shared 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		checkinstall --fstrans=no --install=yes --pkgname="libopencore-amr" --pkgversion="0.1.2" --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext "End opencore")
	else
		echo $(eval_gettext 'Info debut opencore update $VERSION')
		echo $(eval_gettext 'Info debut opencore update $VERSION') 2>> $LOG >> $LOG
		cd opencore-amr-0.1.2
		./configure --enable-shared 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		checkinstall --fstrans=no --install=yes --pkgname="libopencore-amr" --pkgversion="0.1.2" --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext "End opencore")
	fi
	echo
}

# Installation de libtheora
debian_libtheora_install()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	apt-get -y install libogg-dev 2>> $LOG >> $LOG
	LIBTHEORAVERSION=$(dpkg --status libtheora|awk '/^Version/ { print $2 }') 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	VERSION="1.1.1"
	if [ ! -e "$SRC_INSTALL"/libtheora-1.1.1.tar.gz ];then
		echo $(eval_gettext 'Info debut libtheora install $VERSION')
		echo $(eval_gettext 'Info debut libtheora install $VERSION') 2>> $LOG >> $LOG
		wget http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz 2>> $LOG >> $LOG
		tar xzvf libtheora-1.1.1.tar.gz 2>> $LOG >> $LOG
		cd libtheora-1.1.1
		./configure --enable-shared 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		checkinstall --fstrans=no --install=yes --pkgname=libtheora --pkgversion "1.1.1" --backup=no --default 2>> $LOG >> $LOG
		echo $(eval_gettext "End libtheora")
	elif [ "$LIBTHEORAVERSION" == "1.1.1-1" ]; then
		echo $(eval_gettext 'Info a jour libtheora $VERSION')
		echo $(eval_gettext 'Info a jour libtheora $VERSION') 2>> $LOG >> $LOG
	else
		echo $(eval_gettext 'Info debut libtheora update $VERSION')
		echo $(eval_gettext 'Info debut libtheora update $VERSION') 2>> $LOG >> $LOG
		cd libtheora-1.1.1
		./configure --enable-shared 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		checkinstall --fstrans=no --install=yes --pkgname=libtheora --pkgversion "1.1.1" --backup=no --default 2>> $LOG >> $LOG
		echo -n $(eval_gettext "End libtheora")
	fi
	echo
}

# Installation de rtmpdump pour librtmp
debian_rtmpdump_install()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	echo $(eval_gettext "Info debut rtmpdump install")
	echo $(eval_gettext "Info debut rtmpdump install") 2>> $LOG >> $LOG
	apt-get -y install libssl-dev 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	svn co svn://svn.mplayerhq.hu/rtmpdump/trunk rtmpdump 2>> $LOG >> $LOG
	cd rtmpdump
	make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
	make install 2>> $LOG >> $LOG
	echo $(eval_gettext "End rtmpdump")
	echo
}

# Installation de mediainfo
debian_media_info_install()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	MEDIAINFOVERSION=$(mediainfo --Version |awk '/^MediaInfoLib/ { print $3 }') 2>> $LOG >> $LOG
	VERSION="0.7.38"
	if [ ! -e "$SRC_INSTALL"/MediaInfo_CLI_0.7.38_GNU_FromSource.tar.bz2 ];then
		echo $(eval_gettext 'Info debut mediainfo install $VERSION')
		echo $(eval_gettext 'Info debut mediainfo install $VERSION') 2>> $LOG >> $LOG
		cd $SRC_INSTALL
		wget http://downloads.sourceforge.net/project/mediainfo/binary/mediainfo/0.7.38/MediaInfo_CLI_0.7.38_GNU_FromSource.tar.bz2 2>> $LOG >> $LOG
		tar -xvjf MediaInfo_CLI_0.7.38_GNU_FromSource.tar.bz2 2>> $LOG >> $LOG
		cd MediaInfo_CLI_GNU_FromSource
		sh CLI_Compile.sh 2>> $LOG >> $LOG
		cd MediaInfo/Project/GNU/CLI && make install 2>> $LOG >> $LOG
		echo $(eval_gettext "End mediainfo")
	elif [ "$MEDIAINFOVERSION" == "v0.7.38" ]; then
		echo $(eval_gettext 'Info a jour mediainfo $VERSION')
		echo $(eval_gettext 'Info a jour mediainfo $VERSION') 2>> $LOG >> $LOG
	else
		echo $(eval_gettext 'Info debut mediainfo update $VERSION')
		echo $(eval_gettext 'Info debut mediainfo update $VERSION') 2>> $LOG >> $LOG
		cd "$SRC_INSTALL"/MediaInfo_CLI_GNU_FromSource
		sh CLI_Compile.sh 2>> $LOG >> $LOG
		cd MediaInfo/Project/GNU/CLI && make install 2>> $LOG >> $LOG
		echo -n $(eval_gettext "End mediainfo")
	fi
	echo
}

# Installation de php-imagick via pecl
debian_phpimagick_install()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	LATEST=$(pecl remote-info imagick |awk '/^Latest/ { print $2 }') 2>> $LOG >> $LOG
	ACTUEL=$(pecl remote-info imagick |awk '/^Installed/ { print $2 }') 2>> $LOG >> $LOG
	# Cas de l'installation
	if [ "$ACTUEL" == "-" ]; then
		echo $(eval_gettext "Info debut php-imagick install")
		echo $(eval_gettext "Info debut php-imagick install") 2>> $LOG >> $LOG
		echo autodetect | pecl install imagick 2>> $LOG >> $LOG
		echo $(eval_gettext "End php-imagick")
		echo $(eval_gettext "End php-imagick") 2>> $LOG >> $LOG
	# Cas où on a déjà installé la dernière version
	elif [ "$ACTUEL" == "$LATEST" ]; then
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

debian_dep_install()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	echo $(eval_gettext "Info apt maj base")
	echo $(eval_gettext "Info apt maj base") 2>> $LOG >> $LOG
	apt-get -y update 2>> $LOG >> $LOG &
	wait $!
	echo $(eval_gettext "Info apt maj paquets")
	echo $(eval_gettext "Info apt maj paquets") 2>> $LOG >> $LOG
	apt-get -y remove php5-imagick 2>> $LOG >> $LOG &
	wait $!
	
	apt-get -y install build-essential subversion git-core checkinstall libcxxtools-dev scons zlib1g-dev\
		php5-dev php-pear php5-curl php5-gd libmagick9-dev ruby yasm texi2html \
		libfaac-dev libfaad-dev libdirac-dev libgsm1-dev libopenjpeg-dev libxvidcore4-dev libschroedinger-dev libspeex-dev libvorbis-dev \
		flac vorbis-tools liboggkate-dev \
		2>> $LOG >> $LOG
	
	echo 
	
	debian_lame_install || error $(eval_gettext "Erreur installation regarde log") &
	wait $!
	
	debian_libopencore_amr_install || error $(eval_gettext "Erreur installation regarde log") &
	wait $!
	
	debian_libtheora_install || error $(eval_gettext "Erreur installation regarde log") &
	wait $!
	
	debian_rtmpdump_install || error $(eval_gettext "Erreur installation regarde log") &
	wait $!
	
	debian_flvtool_install || error $(eval_gettext "Erreur installation regarde log") &
	wait $!
	
	debian_media_info_install || error $(eval_gettext "Erreur installation regarde log") &
	wait $!
	
	debian_phpimagick_install || error $(eval_gettext "Erreur installation regarde log") &
	wait $!
}

#préconfiguration basique d'Apache
debian_apache_install ()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	echo $(eval_gettext "Info apache mod headers")
	echo $(eval_gettext "Info apache mod headers") 2>> $LOG >> $LOG
	a2enmod headers 2>> $LOG >> $LOG
	echo
	
	echo $(eval_gettext "Info apache mod rewrite")
	echo $(eval_gettext "Info apache mod rewrite") 2>> $LOG >> $LOG
	a2enmod rewrite 2>> $LOG >> $LOG
	echo
	
	echo $(eval_gettext "Info apache mod deflate")
	echo $(eval_gettext "Info apache mod deflate") 2>> $LOG >> $LOG
	a2enmod deflate 2>> $LOG >> $LOG
	echo $(eval_gettext "Info apache mod deflate fichier")
	echo $(eval_gettext "Info apache mod deflate fichier") 2>> $LOG >> $LOG
	cp ./configs/apache/deflate.conf /etc/apache2/conf.d/ 2>> $LOG >> $LOG
	echo
	
	echo $(eval_gettext "Info apache mod expires")
	echo $(eval_gettext "Info apache mod expires") 2>> $LOG >> $LOG
	a2enmod expires 2>> $LOG >> $LOG
	echo $(eval_gettext "Info apache mod expires fichier")
	echo $(eval_gettext "Info apache mod expires fichier") 2>> $LOG >> $LOG
	cp ./configs/apache/expires.conf /etc/apache2/conf.d/ 2>> $LOG >> $LOG
	echo
	
	echo $(eval_gettext "Info apache reload")
	echo $(eval_gettext "Info apache reload") 2>> $LOG >> $LOG
	/etc/init.d/apache2 force-reload 2>> $LOG >> $LOG
	echo
}

#install x264
debian_x264_install ()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	cd $SRC_INSTALL
	git clone git://git.videolan.org/x264.git 2>> $LOG >> $LOG
	cd x264
	./configure --enable-shared 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
	apt-get -y remove x264 libx264-dev 2>> $LOG >> $LOG
	checkinstall --pkgname=x264 --pkgversion "1:0.svn`date +%Y%m%d`-0.0lenny2" --backup=no --default 2>> $LOG >> $LOG
}

debian_x264_update ()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	cd "$SRC_INSTALL"/x264
	REVISION=$(git_log ./ | awk '/^commit/ { print $2 }') 2>> $LOG >> $LOG
	git pull 2>> $LOG >> $LOG
	NEWREVISION=$(git_log ./ | awk '/^commit/ { print $2 }') 2>> $LOG >> $LOG
	if [ "$REVISION" == "$NEWREVISION" ]; then
		echo $(eval_gettext "Info a jour x264")
		echo $(eval_gettext "Info a jour x264") 2>> $LOG >> $LOG
	else
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		./configure --enable-shared 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		apt-get -y remove x264 2>> $LOG >> $LOG
		checkinstall --pkgname=x264 --pkgversion "1:0.svn`date +%Y%m%d`-0.0lenny2" --backup=no --default 2>> $LOG >> $LOG
	fi
}

#install ffmpeg
debian_ffmpeg_install ()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	cd $SRC_INSTALL
	svn checkout svn://svn.ffmpeg.org/ffmpeg/trunk ffmpeg 2>> $LOG >> $LOG
	cd ffmpeg
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')
	make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
	./configure --disable-ffplay --disable-ffserver --enable-gpl --enable-version3 --enable-nonfree --enable-shared --enable-postproc --enable-pthreads \
		--enable-libfaac --enable-libmp3lame --enable-libxvid --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libdirac --enable-libspeex --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib \
		2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
	apt-get -y remove ffmpeg 2>> $LOG >> $LOG
	checkinstall --pkgname=ffmpeg --pkgversion "3:`date +%Y%m%d`.svn$REVISION-18lenny2" --backup=no --default 2>> $LOG >> $LOG
	ldconfig
	cd tools
	cc qt-faststart.c -o qt-faststart 2>> $LOG >> $LOG
	cd ..
	echo
	echo $(eval_gettext 'Info ffmpeg revision $REVISION')
}

debian_ffmpeg_update ()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	cd $SRC_INSTALL/ffmpeg
	svn up 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')
	if [ -x /usr/local/bin/ffmpeg ];then
		VERSION=$(ffmpeg -version  2> $LOG |grep FFmpeg -m 1 |awk '{print $2}')
		REVISION_VERSION=SVN-r"$REVISION"
		if [ "$VERSION" = "$REVISION_VERSION" ];then
			echo $(eval_gettext "Info a jour ffmpeg")
			echo $(eval_gettext "Info a jour ffmpeg") 2>> $LOG >> $LOG
		else
			make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
			make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
			./configure --disable-ffplay --disable-ffserver --enable-gpl --enable-version3 --enable-nonfree --enable-shared --enable-postproc --enable-pthreads \
				--enable-libfaac --enable-libmp3lame --enable-libxvid --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libdirac --enable-libspeex --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib \
				2>> $LOG >> $LOG
			make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
			apt-get -y remove ffmpeg  2>> $LOG >> $LOG
			checkinstall --pkgname=ffmpeg --pkgversion "3:`date +%Y%m%d`.svn$REVISION-18lenny2" --backup=no --default 2>> $LOG >> $LOG
			ldconfig
			cd tools
			cc qt-faststart.c -o qt-faststart 2>> $LOG >> $LOG
			cp qt-faststart /usr/local/bin
		fi
	else
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		./configure --disable-ffplay --disable-ffserver --enable-gpl --enable-version3 --enable-nonfree --enable-shared --enable-postproc --enable-pthreads \
			--enable-libfaac --enable-libmp3lame --enable-libxvid --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libdirac --enable-libspeex --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib \
			2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		checkinstall --pkgname=ffmpeg --pkgversion "3:`date +%Y%m%d`.svn$REVISION-18lenny2" --backup=no --default 2>> $LOG >> $LOG
		ldconfig
		cd tools
		cc qt-faststart.c -o qt-faststart 2>> $LOG >> $LOG
		cp qt-faststart /usr/local/bin
	fi
	echo
	echo $(eval_gettext 'Info ffmpeg revision $REVISION')
}

debian_ffmpeg2theora_install ()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	apt-get -y remove ffmpeg2theora 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	svn checkout http://svn.xiph.org/trunk/ffmpeg2theora ffmpeg2theora 2>> $LOG >> $LOG
	cd ffmpeg2theora
	# Install une version récente de libkate
	sh ./get_libkate.sh 2>> $LOG >> $LOG
	scons install 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo
	echo $(eval_gettext 'Info ffmpeg2theora revision $REVISION')
}

debian_ffmpeg2theora_update ()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	cd "$SRC_INSTALL"/ffmpeg2theora
	svn up 2>> $LOG >> $LOG
	scons install 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')
	echo
	echo $(eval_gettext 'Info ffmpeg2theora revision $REVISION')
}

#install ffmpeg-php
debian_ffmpeg_php_install ()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	apt-get -y remove ffmpeg-php 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	svn co https://ffmpeg-php.svn.sourceforge.net/svnroot/ffmpeg-php/trunk ffmpeg-php 2>> $LOG >> $LOG
	cd ffmpeg-php/ffmpeg-php
	phpize 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
	./configure && make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
	make install 2>> $LOG >> $LOG
	echo 'extension=ffmpeg.so' > /etc/php5/conf.d/ffmpeg.ini
	/etc/init.d/apache2 force-reload 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')
	echo
	echo $(eval_gettext 'Info ffmpeg-php revision $REVISION')
}

debian_ffmpeg_php_update ()
{
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	cd "$SRC_INSTALL"/ffmpeg-php/ffmpeg-php
	OLDREVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')
	svn up 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')
	if [ "$OLDREVISION" = "$REVISION" ];then
		echo
		echo $(eval_gettext "Info a jour ffmpeg-php")
		echo $(eval_gettext "Info a jour ffmpeg-php") 2>> $LOG >> $LOG
	else
		phpize 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		./configure && make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		make install 2>> $LOG >> $LOG
		echo 'extension=ffmpeg.so' > /etc/php5/conf.d/ffmpeg.ini
		/etc/init.d/apache2 force-reload 2>> $LOG >> $LOG
	fi
	echo
	echo $(eval_gettext 'Info ffmpeg-php revision $REVISION')
}