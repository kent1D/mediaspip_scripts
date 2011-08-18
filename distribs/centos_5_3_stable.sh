#!/bin/bash
#
# centos_5_3_stable
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.3.3
#
# Installation des dépendances de manière stable pour centos
#
# Mises à jour :
# Version 0.3.2 - Upgrade de FFmpeg en 0.7.1
# Version 0.3.3 - Upgrade de FFmpeg en 0.7.3

VERSION_CENTOS_STABLE=0.3.3

# Ce script lancé tout seul ne sert à rien
# On s'arrête dès son appel
case "$0" in
	*centos_5_3_stable.sh) 
	printf "
########################################
MediaSPIP Centos stable functions v$VERSION_CENTOS_STABLE
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

centos_rtmpdump_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	
	yum -y install openssl-devel 2>> $LOG >> $LOG
	cd $SRC_INSTALL
	
	VERSION="2.3"
	if [ -x $(which rtmpdump 2>> $LOG) ];then
		RTMPDUMPVERSION=$(pkg-config --modversion librtmp) 2>> $LOG >> $LOG
	fi
	if [ "$RTMPDUMPVERSION" = "v$VERSION" ];then
		echo $(eval_gettext 'Info a jour rtmpdump $VERSION')
		echo $(eval_gettext 'Info a jour rtmpdump $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/rtmpdump-2.3.tgz ];then
			echo $(eval_gettext "Info debut rtmpdump install")
			echo $(eval_gettext "Info debut rtmpdump install") 2>> $LOG >> $LOG
			wget http://rtmpdump.mplayerhq.hu/download/rtmpdump-2.3.tgz 2>> $LOG >> $LOG || return 1
			tar xvzf rtmpdump-2.3.tgz 2>> $LOG >> $LOG || return 1
		fi
		cd rtmpdump-2.3
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "Info compilation install")
		make install 2>> $LOG >> $LOG || return 1
		ldconfig
		#checkinstall --pkgname=rtmpdump --pkgversion "$VERSION+mediaspip" --type=rpm --backup=no --default 2>> $LOG >> $LOG || return 1
		echo $(eval_gettext "End rtmpdump")
	fi
	echo
}

# Installation de ffmpeg2theora
# http://www.v2v.cc/~j/ffmpeg2theora/
centos_5_3_ffmpeg2theora_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	
	cd $SRC_INSTALL
	
	VERSION="0.27"
	if [ -x $(which ffmpeg2theora 2>> $LOG) ];then
		FFMPEG2THEORAVERSION=$(ffmpeg2theora --help |awk '/^ffmpeg2theora/ { print $2 }') 2>> $LOG >> $LOG
	fi
	if [ "$FFMPEG2THEORAVERSION" = "$VERSION" ];then
		echo $(eval_gettext 'Info a jour ffmpeg2theora version $VERSION')
		echo $(eval_gettext 'Info a jour ffmpeg2theora version $VERSION') 2>> $LOG >> $LOG
	else
		if [ ! -e "$SRC_INSTALL"/ffmpeg2theora-0.27.tar.bz2 ];then
			echo $(eval_gettext "Info debut ffmpeg2theora install")
			echo $(eval_gettext "Info debut ffmpeg2theora install") 2>> $LOG >> $LOG
			wget http://v2v.cc/~j/ffmpeg2theora/downloads/ffmpeg2theora-0.27.tar.bz2 2>> $LOG >> $LOG || return 1
			tar xvjf ffmpeg2theora-0.27.tar.bz2 2>> $LOG >> $LOG
			cd ffmpeg2theora-0.27
			sh ./get_libkate.sh 2>> $LOG >> $LOG || return 1
		else
			cd ffmpeg2theora-0.27
			echo $(eval_gettext "Info debut ffmpeg2theora update")
			echo $(eval_gettext "Info debut ffmpeg2theora update") 2>> $LOG >> $LOG
		fi
		scons install 2>> $LOG >> $LOG || return 1
		echo
		echo $(eval_gettext 'Info ffmpeg2theora version $VERSION')
		echo
	fi
}

# Installation de FFMpeg
# http://www.ffmpeg.org
centos_5_3_ffmpeg_install ()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip
	cd $SRC_INSTALL
	if [  ! -e "$SRC_INSTALL"/ffmpeg-0.7.3.tar.bz2 ];then
		echo $(eval_gettext "Info debut ffmpeg install")
		echo $(eval_gettext "Info debut ffmpeg install") 2>> $LOG >> $LOG
		echo
		wget http://ffmpeg.org/releases/ffmpeg-0.7.3.tar.bz2 2>> $LOG >> $LOG
		tar xvjf ffmpeg-0.7.3.tar.bz2 2>> $LOG >> $LOG
	elif [ ! -d ffmpeg-0.7.3 ];then
		tar xvjf ffmpeg-0.7.3.tar.bz2 2>> $LOG >> $LOG
	fi
	
	VERSION="0.7.3"
	if [ -x $(which ffmpeg 2>> $LOG) ];then
		VERSION_ACTUELLE=$(ffmpeg -version  2> /dev/null |grep FFmpeg -m 1 |awk '{print $2}')
	fi
	
	cd $SRC_INSTALL/ffmpeg-0.7.3
	
	if [ "$VERSION" = "$VERSION_ACTUELLE" ];then
		echo $(eval_gettext "Info a jour ffmpeg")
		echo $(eval_gettext "Info a jour ffmpeg") 2>> $LOG >> $LOG
	else
		make -j $NO_OF_CPUCORES clean 2>> $LOG >> $LOG
		make -j $NO_OF_CPUCORES distclean 2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation configure")
		./configure --disable-ffplay --disable-ffserver --enable-gpl --enable-version3 --enable-nonfree --enable-shared --enable-postproc --enable-pthreads --enable-libvpx  \
			--enable-libfaac --enable-libmp3lame --enable-libxvid --disable-encoder=vorbis  --enable-libvorbis --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libx264 --enable-libdirac --enable-librtmp --enable-libopenjpeg --enable-libgsm --enable-avfilter --enable-zlib \
			2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation make")
		make -j $NO_OF_CPUCORES 2>> $LOG >> $LOG || return 1
		yum -y erase ffmpeg  2>> $LOG >> $LOG
		echo $(eval_gettext "Info compilation install")
		make install 2>> $LOG >> $LOG || return 1
		#checkinstall --pkgname=ffmpeg --pkgversion "3:`date +%Y%m%d`-$VERSION+mediaspip" --type=rpm --backup=no --default 2>> $LOG >> $LOG || return 1
		ldconfig
		cd tools
		cc qt-faststart.c -o qt-faststart 2>> $LOG >> $LOG
		cp qt-faststart /usr/local/bin
	fi
	echo
	echo $(eval_gettext 'Info ffmpeg version $VERSION')
}