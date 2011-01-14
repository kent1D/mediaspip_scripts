#!/bin/bash
#
# mediaspip_functions
# Version 0.2
#
# Diverses fonctions permettant d'installer mediaSPIP

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

function progress_indicator()
{
	#this is a simple progress indicator
	while ps |grep $1 &>/dev/null; do
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
	#install flvtool2
	echo
	eval_gettext "Info debut flvtool2"
	eval_gettext "Info debut flvtool2" 2>> $LOG  >> $LOG
	cd $SRC_INSTALL
	svn checkout svn://rubyforge.org/var/svn/flvtool2/trunk flvtool2 2>> $LOG  >> /dev/null
	cd flvtool2
	sudo ruby setup.rb 2>> $LOG  >> /dev/null
	eval_gettext "End flvtool2"
}

# Installation de Lame
debian_lame_install()
{
	LAMEVERSION=$(lame --version |awk '/^LAME/ { print $4 }') 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	if [ ! -e "$SRC_INSTALL"/lame-3.98.4.tar.gz ]; then
		echo
		eval_gettext "Info debut lame install" 
		eval_gettext "Info debut lame" 2>> $LOG  >> $LOG
		wget http://downloads.sourceforge.net/project/lame/lame/3.98.4/lame-3.98.4.tar.gz 2>> $LOG >> $LOG
		tar xvf lame-3.98.4.tar.gz 2>> $LOG  >> /dev/null
		cd lame-3.98.4
		./configure 2>> $LOG >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname="libmp3lame" --pkgversion="3.98.4" --backup=no --default 2>> $LOG  >> /dev/null
		eval_gettext "End lame"
	elif [ "$LAMEVERSION" == "3.98.4" ]; then
		echo
		eval_gettext "Info a jour lame"
		eval_gettext "Info a jour lame" 2>> $LOG  >> $LOG
	else
		echo
		eval_gettext "Info debut lame update" 
		eval_gettext "Info debut lame update" 2>> $LOG  >> $LOG
		cd lame-3.98.4
		./configure 2>> $LOG >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname="libmp3lame" --pkgversion="3.98.4" --backup=no --default 2>> $LOG  >> /dev/null
		eval_gettext "End lame"
	fi
}

# Installation de libopencore-amr
debian_libopencore_amr_install()
{
	LIBOPENCORE=$(dpkg --status libopencore-amr|awk '/^Version/ { print $2 }') 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	if [ ! -e "$SRC_INSTALL"/opencore-amr-0.1.2.tar.gz ];then
		echo
		eval_gettext "Info debut opencore install"
		eval_gettext "Info debut opencore install" 2>> $LOG >> $LOG
		wget http://transact.dl.sourceforge.net/project/opencore-amr/opencore-amr/0.1.2/opencore-amr-0.1.2.tar.gz 2>> $LOG >> $LOG
		tar xvf opencore-amr-0.1.2.tar.gz 2>> $LOG  >> /dev/null
		cd opencore-amr-0.1.2
		./configure --enable-shared 2>> $LOG  >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname="libopencore-amr" --pkgversion="0.1.2" --backup=no --default 2>> $LOG  >> /dev/null
		eval_gettext "End opencore"
	elif [ "$LIBOPENCORE" == "0.1.2-1" ]; then
		echo
		eval_gettext "Info a jour opencore"
		eval_gettext "Info a jour opencore" 2>> $LOG  >> $LOG
	else
		echo
		eval_gettext "Info debut opencore update"
		eval_gettext "Info debut opencore update" 2>> $LOG  >> $LOG
		cd opencore-amr-0.1.2
		./configure --enable-shared 2>> $LOG  >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname="libopencore-amr" --pkgversion="0.1.2" --backup=no --default 2>> $LOG  >> /dev/null
		eval_gettext "End opencore"
	fi
}

# Installation de libtheora
debian_libtheora_install()
{
	apt-get -y install libogg-dev 2>> $LOG  >> /dev/null
	LIBTHEORAVERSION=$(dpkg --status libtheora|awk '/^Version/ { print $2 }') 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	if [ ! -e "$SRC_INSTALL"/libtheora-1.1.1.tar.gz ];then
		echo
		eval_gettext "Info debut libtheora install"
		eval_gettext "Info debut libtheora install" 2>> $LOG >> $LOG
		wget http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz 2>> $LOG >> $LOG
		tar xzvf libtheora-1.1.1.tar.gz 2>> $LOG  >> /dev/null
		cd libtheora-1.1.1
		./configure --enable-shared 2>> $LOG  >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname=libtheora --pkgversion "1.1.1" --backup=no --default 2>> $LOG >> /dev/null
		eval_gettext "End libtheora"
	elif [ "$LIBTHEORAVERSION" == "1.1.1-1" ]; then
		echo
		eval_gettext "Info a jour libtheora"
		eval_gettext "Info a jour libtheora" 2>> $LOG  >> $LOG
	else
		echo
		eval_gettext "Info debut libtheora update"
		eval_gettext "Info debut libtheora update" 2>> $LOG >> $LOG
		cd libtheora-1.1.1
		./configure --enable-shared 2>> $LOG  >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname=libtheora --pkgversion "1.1.1" --backup=no --default 2>> $LOG >> /dev/null
		eval_gettext "End libtheora"
	fi
}

# Installation de rtmpdump pour librtmp
debian_rtmpdump_install()
{
	echo
	eval_gettext "Info debut rtmpdump install"
	eval_gettext "Info debut rtmpdump install" 2>> $LOG >> $LOG
	apt-get -y install libssl-dev 2>> $LOG  >> /dev/null
	cd $SRC_INSTALL
	svn co svn://svn.mplayerhq.hu/rtmpdump/trunk rtmpdump 2>> $LOG  >> /dev/null
	cd rtmpdump
	make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
	make install 2>> $LOG  >> /dev/null
	eval_gettext "End rtmpdump"
}

# Installation de mediainfo
debian_media_info_install()
{
	#install mediainfo
	MEDIAINFOVERSION=$(mediainfo --Version |awk '/^MediaInfoLib/ { print $3 }') 2>> $LOG >> $LOG
	if [ ! -e "$SRC_INSTALL"/MediaInfo_CLI_0.7.38_GNU_FromSource.tar.bz2 ];then
		echo
		echo "Téléchargement, compilation et installation de mediainfo version 0.7.38"
		echo "Téléchargement, compilation et installation de mediainfo version 0.7.38" 2>> $LOG >> $LOG
		cd $SRC_INSTALL
		wget http://downloads.sourceforge.net/project/mediainfo/binary/mediainfo/0.7.38/MediaInfo_CLI_0.7.38_GNU_FromSource.tar.bz2 2>> $LOG >> $LOG
		tar -xvjf MediaInfo_CLI_0.7.38_GNU_FromSource.tar.bz2 2>> $LOG  >> /dev/null
		cd MediaInfo_CLI_GNU_FromSource
		sh CLI_Compile.sh 2>> $LOG  >> /dev/null
		cd MediaInfo/Project/GNU/CLI && make install 2>> $LOG >> $LOG
		echo -e "\bInstallation de MediaInfo terminée"
	elif [ "$MEDIAINFOVERSION" == "v0.7.38" ]; then
		echo
		echo "MediaInfo semble déjà à la version 0.7.38"
		echo "MediaInfo semble déjà à la version 0.7.38" 2>> $LOG >> $LOG
	else
		echo "Recompilation et réinstallation de mediainfo version 0.7.38"
		echo "Recompilation et réinstallation de mediainfo version 0.7.38" 2>> $LOG >> $LOG
		cd 	"$SRC_INSTALL"/MediaInfo_CLI_GNU_FromSource
		sh CLI_Compile.sh 2>> $LOG  >> /dev/null
		cd MediaInfo/Project/GNU/CLI && make install 2>> $LOG >> $LOG
		echo -e "\bInstallation de MediaInfo terminée"
	fi
}

# Installation de php-imagick via pecl
debian_phpimagick_install()
{
	echo
	LATEST=$(pecl remote-info imagick |awk '/^Latest/ { print $2 }') 2>> $LOG >> $LOG
	ACTUEL=$(pecl remote-info imagick |awk '/^Installed/ { print $2 }') 2>> $LOG >> $LOG
	# Cas de l'installation
	if [ "$ACTUEL" == "-" ]; then
		# Installation
		echo "Installation de php-imagick à la version $LATEST"
		echo "Installation de php-imagick à la version $LATEST" 2>> $LOG >> $LOG
		echo autodetect | pecl install imagick 2>> $LOG >> $LOG
		echo -e "\bInstallation de php-imagick terminée"
		echo -e "\bInstallation de php-imagick terminée" 2>> $LOG >> $LOG
	# Cas où on a déjà installé la dernière version
	elif [ "$ACTUEL" == "$LATEST" ]; then
		# Déjà à jour
		echo "php-imagick semble déjà à jour (v.$LATEST)"
		echo "php-imagick semble déjà à jour (v.$LATEST)" 2>> $LOG >> $LOG
	# Cas de la mise à jour
	else
		# Mise à jour
		echo "Mise à jour de php-imagick à la version $LATEST"
		echo "Mise à jour de php-imagick à la version $LATEST" 2>> $LOG >> $LOG
		pecl upgrade imagick 2>> $LOG >> $LOG
		echo -e "\bMise à jour de php-imagick terminée"
		echo -e "\bMise à jour de php-imagick terminée" 2>> $LOG >> $LOG
	fi
}

debian_dep_install()
{
	echo "Mise à jour de la base d'APT" 2>> $LOG >> $LOG
	apt-get -y update 2>> $LOG >> /dev/null
	echo "Installation ou mise à jour des paquets via APT" 2>> $LOG  >> $LOG
	apt-get -y remove php5-imagick 2>> $LOG  >> $LOG
	apt-get -y install build-essential subversion git-core checkinstall php5-dev php-pear php5-curl php5-gd libmagick9-dev ruby yasm texi2html libfaac-dev libfaad-dev libdirac-dev libgsm1-dev libopenjpeg-dev libxvidcore4-dev libschroedinger-dev libspeex-dev libvorbis-dev flac vorbis-tools zlib1g-dev scons liboggkate-dev libcxxtools-dev 2>> $LOG  >> /dev/null
	
	debian_lame_install
	
	debian_libopencore_amr_install
	
	debian_libtheora_install
	
	debian_rtmpdump_install
	
	debian_flvtool_install
	
	debian_media_info_install
	
	debian_phpimagick_install
}

#install x264
debian_x264_install ()
{
	apt-get -y remove x264 libx264-dev 2>> $LOG  >> /dev/null
	cd $SRC_INSTALL
	git clone git://git.videolan.org/x264.git 2>> $LOG  >> /dev/null
	cd x264
	./configure --enable-shared 2>> $LOG  >> /dev/null
	make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
	checkinstall --pkgname=x264 --pkgversion "1:0.svn`date +%Y%m%d`-0.0lenny2" --backup=no --default 2>> $LOG  >> /dev/null
}

debian_x264_update ()
{
	cd "$SRC_INSTALL"/x264
	REVISION=$(git_log ./ | awk '/^commit/ { print $2 }') 2>> $LOG >> $LOG
	git pull 2>> $LOG >> $LOG
	NEWREVISION=$(git_log ./ | awk '/^commit/ { print $2 }') 2>> $LOG >> $LOG
	if [ "$REVISION" == "$NEWREVISION" ]; then
		echo "x264 semble déjà à jour" 
		echo "x264 semble déjà à jour" 2>> $LOG  >> $LOG
	else
		apt-get -y remove x264 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES distclean 2>> $LOG  >> /dev/null
		./configure --enable-shared 2>> $LOG  >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
		checkinstall --pkgname=x264 --pkgversion "1:0.svn`date +%Y%m%d`-0.0lenny2" --backup=no --default 2>> $LOG  >> /dev/null
	fi
}

#install ffmpeg
debian_ffmpeg_install ()
{
	apt-get -y remove ffmpeg 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	svn checkout svn://svn.ffmpeg.org/ffmpeg/trunk ffmpeg 2>> $LOG >> $LOG
	cd ffmpeg
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
	make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
	./configure --enable-gpl --enable-version3 --enable-nonfree --enable-shared --enable-postproc --enable-pthreads --enable-libfaac --enable-libmp3lame --enable-libxvid --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libdirac --enable-libspeex --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib 2>> $LOG >> /dev/null																															      
	make -j $NO_OF_CPUCORES 2>> $LOG >> /dev/null
	checkinstall --pkgname=ffmpeg --pkgversion "3:`date +%Y%m%d`.svn$REVISION-18lenny2" --backup=no --default 2>> $LOG >> $LOG
	ldconfig
	cd tools
	cc qt-faststart.c -o qt-faststart
	cd ..
	echo
	echo "FFMpeg est installé à la révision $REVISION"
}

debian_ffmpeg_update ()
{
	cd $SRC_INSTALL/ffmpeg
	svn up 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }')  2>> $LOG >> $LOG
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
			checkinstall --pkgname=ffmpeg --pkgversion "3:`date +%Y%m%d`.svn$REVISION-18lenny2" --backup=no --default 2>> $LOG >> $LOG
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
		checkinstall --pkgname=ffmpeg --pkgversion "3:`date +%Y%m%d`.svn$REVISION-18lenny2" --backup=no --default 2>> $LOG >> $LOG
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
	cd $SRC_INSTALL
	svn checkout http://svn.xiph.org/trunk/ffmpeg2theora ffmpeg2theora 2>> $LOG >> $LOG
	cd ffmpeg2theora
	# Install une version récente de libkate
	sh ./get_libkate.sh 2>> $LOG >> $LOG
	scons install 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo
	echo "ffmpeg2theora est installé à la révision $REVISION"
}

debian_ffmpeg2theora_update ()
{
	cd "$SRC_INSTALL"/ffmpeg2theora
	svn up 2>> $LOG >> $LOG
	scons install 2>> $LOG >> $LOG
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo
	echo "ffmpeg2theora est installé à la révision $REVISION"
}

#install ffmpeg-php
debian_ffmpeg_php_install ()
{
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
	REVISION=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo
	echo "FFMpeg-php est installé à la révision $REVISION"
}

debian_ffmpeg_php_update ()
{
	cd "$SRC_INSTALL"/ffmpeg-php/ffmpeg-php
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
		make install 2>> $LOG >> $LOG
		echo 'extension=ffmpeg.so' > /etc/php5/conf.d/ffmpeg.ini
		/etc/init.d/apache2 force-reload 2>> $LOG >> $LOG
	fi
	echo "FFMpeg-php est installé à la révision $REVISION"
}