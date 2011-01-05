#!/bin/bash
#
# mediaspip_functions
# Version 0.1

function isNumeric()
{
	echo "$@" | grep -q -v "[^0-9]"
}

debian_flvtool_install()
{
	#install flvtool2
	echo
	echo "Téléchargement, compilation et installation de flvtool2"
	echo "Téléchargement, compilation et installation de flvtool2" 2>> $LOG  >> $LOG
	cd $INSTALL
	svn checkout svn://rubyforge.org/var/svn/flvtool2/trunk flvtool2 2>> $LOG  >> /dev/null
	cd flvtool2
	sudo ruby setup.rb 2>> $LOG  >> /dev/null
	echo -e "\bInstallation de flvtool2 terminée"
}

debian_lame_install()
{
	#install lame
	LAMEVERSION=$(lame --version |awk '/^LAME/ { print $4 }') 2>> $LOG >> $LOG
	cd $INSTALL
	if [ ! -e "$INSTALL"/lame-3.98.4.tar.gz ]; then
		echo
		echo "Téléchargement, compilation et installation de lame version 3.98.4"
		echo "Téléchargement, compilation et installation de lame version 3.98.4" 2>> $LOG  >> $LOG
		wget http://downloads.sourceforge.net/project/lame/lame/3.98.4/lame-3.98.4.tar.gz 2>> $LOG >> $LOG
		tar xvf lame-3.98.4.tar.gz 2>> $LOG  >> /dev/null
		cd lame-3.98.4
		./configure 2>> $LOG >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname="libmp3lame" --pkgversion="3.98.4" --backup=no --default 2>> $LOG  >> /dev/null
		echo -e "\bInstallation de lame terminée"
	elif [ "$LAMEVERSION" == "3.98.4" ]; then
		echo
		echo "LAME semble déjà à la version 3.98.4" 
		echo "LAME semble déjà à la version 3.98.4" 2>> $LOG  >> $LOG
	else
		echo
		echo "Recompilation et réinstallation de lame version 3.98.4"
		echo "Recompilation et réinstallation de lame version 3.98.4" 2>> $LOG  >> $LOG
		cd lame-3.98.4
		./configure 2>> $LOG >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname="libmp3lame" --pkgversion="3.98.4" --backup=no --default 2>> $LOG  >> /dev/null
		echo -e "\bInstallation de lame terminée"
	fi
}

debian_libopencore_amr_install()
{
	#install libopencore-amr
	LIBOPENCORE=$(dpkg --status libopencore-amr|awk '/^Version/ { print $2 }') 2>> $LOG >> $LOG
	cd $INSTALL
	if [ ! -e "$INSTALL"/opencore-amr-0.1.2.tar.gz ];then
		echo
		echo "Téléchargement, compilation et installation de opencore-amr version 0.1.2"
		echo "Téléchargement, compilation et installation de opencore-amr version 0.1.2" 2>> $LOG >> $LOG
		wget http://transact.dl.sourceforge.net/project/opencore-amr/opencore-amr/0.1.2/opencore-amr-0.1.2.tar.gz 2>> $LOG >> $LOG
		tar xvf opencore-amr-0.1.2.tar.gz 2>> $LOG  >> /dev/null
		cd opencore-amr-0.1.2
		./configure --enable-shared 2>> $LOG  >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname="libopencore-amr" --pkgversion="0.1.2" --backup=no --default 2>> $LOG  >> /dev/null
		echo -e "\bInstallation de opencore-amr terminée"
	elif [ "$LIBOPENCORE" == "0.1.2-1" ]; then
		echo
		echo "Libopencore-amr semble déjà à la version 0.1.2" 
		echo "Libopencore-amr semble déjà à la version 0.1.2" 2>> $LOG  >> $LOG
	else
		echo
		echo "Recompilation et réinstallation de opencore-amr version 0.1.2"
		echo "Recompilation et réinstallation de opencore-amr version 0.1.2" 2>> $LOG  >> $LOG
		cd opencore-amr-0.1.2
		./configure --enable-shared 2>> $LOG  >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname="libopencore-amr" --pkgversion="0.1.2" --backup=no --default 2>> $LOG  >> /dev/null
		echo -e "\bInstallation de opencore-amr terminée"
	fi
}

debian_libtheora_install()
{
	#install libtheora
	apt-get -y install libogg-dev 2>> $LOG  >> /dev/null
	LIBTHEORAVERSION=$(dpkg --status libtheora|awk '/^Version/ { print $2 }') 2>> $LOG >> $LOG
	cd $INSTALL
	if [ ! -e "$INSTALL"/libtheora-1.1.1.tar.gz ];then
		echo
		echo "Téléchargement, compilation et installation de libtheora version 1.1.1"
		echo "Téléchargement, compilation et installation de libtheora version 1.1.1" 2>> $LOG >> $LOG
		wget http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz 2>> $LOG >> $LOG
		tar xzvf libtheora-1.1.1.tar.gz 2>> $LOG  >> /dev/null
		cd libtheora-1.1.1
		./configure --enable-shared 2>> $LOG  >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname=libtheora --pkgversion "1.1.1" --backup=no --default 2>> $LOG >> /dev/null
		echo -e "\bInstallation de libtheora terminée"
	elif [ "$LIBTHEORAVERSION" == "1.1.1-1" ]; then
		echo
		echo "Libtheora semble déjà à la version 1.1.1" 
		echo "Libtheora semble déjà à la version 1.1.1" 2>> $LOG  >> $LOG
	else
		echo
		echo "Recompilation et réinstallation de libtheora version 1.1.1"
		echo "Recompilation et réinstallation de libtheora version 1.1.1" 2>> $LOG >> $LOG
		cd libtheora-1.1.1
		./configure --enable-shared 2>> $LOG  >> /dev/null
		make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
		checkinstall --fstrans=no --install=yes --pkgname=libtheora --pkgversion "1.1.1" --backup=no --default 2>> $LOG >> /dev/null
		echo -e "\bInstallation de libtheora terminée"
	fi
}

debian_rtmpdump_install()
{
	#install rtmpdump pour librtmp
	echo
	echo "Téléchargement, compilation et installation de rtmpdump"
	echo "Téléchargement, compilation et installation de rtmpdump" 2>> $LOG >> $LOG
	apt-get -y install libssl-dev 2>> $LOG  >> /dev/null
	cd $INSTALL
	svn co svn://svn.mplayerhq.hu/rtmpdump/trunk rtmpdump 2>> $LOG  >> /dev/null
	cd rtmpdump
	make -j $NO_OF_CPUCORES 2>> $LOG  >> /dev/null
	make install 2>> $LOG  >> /dev/null
	echo -e "\bInstallation de rtmpdump terminée"
}

debian_media_info_install()
{
	#install mediainfo
	MEDIAINFOVERSION=$(mediainfo --Version |awk '/^MediaInfoLib/ { print $3 }') 2>> $LOG >> $LOG
	if [ ! -e "$INSTALL"/MediaInfo_CLI_0.7.38_GNU_FromSource.tar.bz2 ];then
		echo "Téléchargement, compilation et installation de mediainfo version 0.7.38"
		echo "Téléchargement, compilation et installation de mediainfo version 0.7.38" 2>> $LOG >> $LOG
		cd $INSTALL
		wget http://downloads.sourceforge.net/project/mediainfo/binary/mediainfo/0.7.38/MediaInfo_CLI_0.7.38_GNU_FromSource.tar.bz2 2>> $LOG >> $LOG
		tar -xvjf MediaInfo_CLI_0.7.38_GNU_FromSource.tar.bz2 2>> $LOG  >> /dev/null
		cd MediaInfo_CLI_GNU_FromSource
		sh CLI_Compile.sh 2>> $LOG  >> /dev/null
		cd MediaInfo/Project/GNU/CLI && make install 2>> $LOG  >> /dev/null
		echo -e "\bInstallation de MediaInfo terminée"
	elif [ "$MEDIAINFOVERSION" == "v0.7.38" ]; then
		echo
		echo "MediaInfo semble déjà à la version 0.7.38"
	else
		echo "Recompilation et réinstallation de mediainfo version 0.7.38"
		echo "Recompilation et réinstallation de mediainfo version 0.7.38" 2>> $LOG >> $LOG
		cd 	"$INSTALL"/MediaInfo_CLI_GNU_FromSource
		sh CLI_Compile.sh 2>> $LOG  >> /dev/null
		cd MediaInfo/Project/GNU/CLI && make install 2>> $LOG  >> /dev/null
		echo -e "\bInstallation de MediaInfo terminée"
	fi
}