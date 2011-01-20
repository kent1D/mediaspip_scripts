#!/bin/bash
#
# debian_stable
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.2
#
# Installation des dépendances de manière stable pour debian

# Installation de rtmpdump pour librtmp
# http://rtmpdump.mplayerhq.hu/
debian_rtmpdump_install()
{
	PID=$!
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	
	apt-get -y install libssl-dev 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	
	VERSION="v2.3"
	if [ -x /usr/local/bin/rtmpdump ];then
		RTMPDUMPVERSION=$(pkg-config --modversion librtmp) 2>> $LOG >> $LOG
	fi
	if [ "$RTMPDUMPVERSION" = "$VERSION" ];then
		echo $(eval_gettext 'Info a jour rtmpdump $VERSION')
		echo $(eval_gettext 'Info a jour rtmpdump $VERSION') 2>> $LOG >> $LOG
	elif [ ! -e "$SRC_INSTALL"/rtmpdump-2.3.tgz ];then
		echo $(eval_gettext "Info debut rtmpdump install")
		echo $(eval_gettext "Info debut rtmpdump install") 2>> $LOG >> $LOG
		wget http://rtmpdump.mplayerhq.hu/download/rtmpdump-2.3.tgz 2>> $LOG >> $LOG
		tar xvz rtmpdump-2.3.tgz 2>> $LOG >> $LOG
		cd rtmpdump-2.3
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		checkinstall --pkgname=rtmpdump --pkgversion "2.3-lenny2" --backup=no --default 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		echo $(eval_gettext "End rtmpdump")
	else
		cd rtmpdump-2.3
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		checkinstall --pkgname=rtmpdump --pkgversion "2.3-lenny2" --backup=no --default 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		echo $(eval_gettext "End rtmpdump")
	fi
	echo
}

# Installation de ffmpeg2theora
# http://www.v2v.cc/~j/ffmpeg2theora/
debian_ffmpeg2theora_install()
{
	PID=$!
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	
	cd $SRC_INSTALL
	
	VERSION="0.27"
	if [ -x /usr/local/bin/ffmpeg2theora ];then
		FFMPEG2THEORAVERSION=$(ffmpeg2theora --help |awk '/^ffmpeg2theora/ { print $2 }') 2>> $LOG >> $LOG
	fi
	if [ "$FFMPEG2THEORAVERSION" = "$VERSION" ];then
		echo $(eval_gettext 'Info a jour ffmpeg2theora version $VERSION')
		echo $(eval_gettext 'Info a jour ffmpeg2theora version $VERSION') 2>> $LOG >> $LOG
	elif [ ! -e "$SRC_INSTALL"/ffmpeg2theora-0.27.tar.bz2 ];then
		echo $(eval_gettext "Info debut ffmpeg2theora install")
		echo $(eval_gettext "Info debut ffmpeg2theora install") 2>> $LOG >> $LOG
		wget http://v2v.cc/~j/ffmpeg2theora/downloads/ffmpeg2theora-0.27.tar.bz2 2>> $LOG >> $LOG
		tar xvjf ffmpeg2theora-0.27.tar.bz2 2>> $LOG >> $LOG
		cd ffmpeg2theora-0.27
		sh ./get_libkate.sh
		scons install 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		echo
		echo $(eval_gettext 'Info ffmpeg2theora version $REVISION')
		echo
	else
		cd ffmpeg2theora-0.27
		echo $(eval_gettext "Info debut ffmpeg2theora update")
		echo $(eval_gettext "Info debut ffmpeg2theora update") 2>> $LOG >> $LOG
		scons install 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		echo
		echo $(eval_gettext 'Info ffmpeg2theora version $REVISION')
		echo
	fi
}

# Installation de FFMpeg
# http://www.ffmpeg.org
debian_ffmpeg_install ()
{
	PID=$!
	export TEXTDOMAINDIR=$(pwd)/locale
	export TEXTDOMAIN=mediaspip
	cd $SRC_INSTALL
	if [  ! -e "$SRC_INSTALL"/ffmpeg-0.6.1.tar.bz2 ];then
		echo $(eval_gettext "Info debut ffmpeg install")
		echo
		echo $(eval_gettext "Info debut ffmpeg install") 2>> $LOG >> $LOG
		wget http://ffmpeg.org/releases/ffmpeg-0.6.1.tar.bz2 2>> $LOG >> $LOG
		tar xvjf ffmpeg-0.6.1.tar.bz2 2>> $LOG >> $LOG
	elif [ ! -d ffmpeg-0.6.1 ];then
		tar xvjf ffmpeg-0.6.1.tar.bz2 2>> $LOG >> $LOG
	fi
	
	VERSION="0.6.1" 2>> $LOG >> $LOG
	if [ -x /usr/local/bin/ffmpeg ];then
		VERSION_ACTUELLE=$(ffmpeg -version  2> /dev/null |grep FFmpeg -m 1 |awk '{print $2}')
	fi
	
	cd $SRC_INSTALL/ffmpeg-0.6.1
	
	if [ "$VERSION" == "$VERSION_ACTUELLE" ];then
		echo $(eval_gettext "Info a jour ffmpeg")
		echo $(eval_gettext "Info a jour ffmpeg") 2>> $LOG >> $LOG
	else
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation configure")
		./configure --disable-ffplay --disable-ffserver --enable-gpl --enable-version3 --enable-nonfree --enable-shared --enable-postproc --enable-pthreads --enable-libvpx  \
			--enable-libfaac --enable-libmp3lame --enable-libxvid --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libdirac --enable-libspeex --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib \
			2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		apt-get -y remove ffmpeg  2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		checkinstall --pkgname=ffmpeg --pkgversion "3:`date +%Y%m%d`-$VERSION-mediaspip" --backup=no --default 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		ldconfig
		cd tools
		cc qt-faststart.c -o qt-faststart 2>> $LOG >> $LOG
		cp qt-faststart /usr/local/bin
	fi
	echo
	echo $(eval_gettext 'Info ffmpeg version $VERSION')
}