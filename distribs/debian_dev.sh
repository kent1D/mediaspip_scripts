#!/bin/bash
#
# debian_dev
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.2
#
# Installation des dépendances en version de développement pour debian

# Installation de rtmpdump pour librtmp
# http://rtmpdump.mplayerhq.hu/
debian_rtmpdump_install()
{
	PID=$!
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	if [ -d $SRC_INSTALL/rtmpdump/.svn ];then
		ACTUEL=$(svnversion $SRC_INSTALL/rtmpdump/) 2>> $LOG >> $LOG
		cd $SRC_INSTALL/rtmpdump/
		svn up 2>> $LOG >> $LOG
	else
		cd $SRC_INSTALL
		svn co svn://svn.mplayerhq.hu/rtmpdump/trunk rtmpdump 2>> $LOG >> $LOG
		cd rtmpdump
	fi
	REVISION=$(svnversion $SRC_INSTALL/rtmpdump/) 2>> $LOG >> $LOG
	
	if [ "$ACTUEL" == "$REVISION" ];then
		echo $(eval_gettext "Info a jour rtmpdump $REVISION")
		echo $(eval_gettext "Info a jour rtmpdump $REVISION") 2>> $LOG >> $LOG
	else
		echo $(eval_gettext "Info debut rtmpdump install")
		echo $(eval_gettext "Info debut rtmpdump install") 2>> $LOG >> $LOG
		apt-get -y install libssl-dev 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		make install 2>> $LOG >> $LOG
		echo $(eval_gettext "End rtmpdump")
	fi
	echo
}

# Installation de FFMpeg
# http://www.ffmpeg.org
debian_ffmpeg_install ()
{
	PID=$!
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	cd $SRC_INSTALL
	if [ -d "$SRC_INSTALL"/ffmpeg-git/.git ];then
		echo $(eval_gettext "Info debut ffmpeg update")
		echo
		echo $(eval_gettext "Info debut ffmpeg update") 2>> $LOG >> $LOG
		cd $SRC_INSTALL/ffmpeg-git
		git pull 2>> $LOG >> $LOG
	else
		echo $(eval_gettext "Info debut ffmpeg install")
		echo
		echo $(eval_gettext "Info debut ffmpeg install") 2>> $LOG >> $LOG
		git clone git://git.videolan.org/ffmpeg ffmpeg-git 2>> $LOG >> $LOG
		cd $SRC_INSTALL/ffmpeg-git
	fi
	
	REVISION=$(git_log ./ | awk '/^== Short Revision:/ { print $4 }') 2>> $LOG >> $LOG
	if [ -x /usr/local/bin/ffmpeg ];then
		VERSION=$(ffmpeg -version  2> /dev/null |grep FFmpeg -m 1 |awk '{print $2}')
		REVISION_VERSION=git-"$REVISION"
	fi
	
	if [ "$VERSION" = "$REVISION_VERSION" ];then
		echo $(eval_gettext "Info a jour ffmpeg")
		echo $(eval_gettext "Info a jour ffmpeg") 2>> $LOG >> $LOG
	else
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation configure")
		./configure --disable-ffplay --disable-ffserver --enable-gpl --enable-version3 --enable-nonfree --enable-shared --enable-postproc --enable-pthreads \
			--enable-libfaac --enable-libmp3lame --enable-libxvid --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libdirac --enable-libspeex --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib \
			2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		apt-get -y remove ffmpeg  2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		checkinstall --pkgname=ffmpeg --pkgversion "3:`date +%Y%m%d`.git$REVISION-18lenny2" --backup=no --default 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		ldconfig
		cd tools
		cc qt-faststart.c -o qt-faststart 2>> $LOG >> $LOG
		cp qt-faststart /usr/local/bin
	fi
	echo
	echo $(eval_gettext 'Info ffmpeg revision $REVISION')
}