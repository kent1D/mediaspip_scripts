#!/bin/bash
# ffmpegupreverse
# a script to reverse the installation ONLY of x264 and ffmpeg by my ffmpegup and / or newinstall scripts

# taken from the excellet tutorial found here:
# http://ubuntuforums.org/showthread.php?t=786095&highlight=ffmpeg+x264+latest
# all props to fakeoutdoorsman, not me
# check http://code.google.com/p/x264-ffmpeg-up-to-date/ for updates
# ver 1.1 by rupert plumridge
# 6th November 2010
# added support for Ubuntu Maverick
######################################
# ver 1.0BETA by rupert plumridge
# 16th April 2010
# first version released
# this is a BETA script, so it may not work as expected and may destroy the world, including your computer..use at your own risk.
# THIS SCRIPT DELETES THE SOURCE FILES AND FOLDERS FROM YOUR COMPUTER, BE SURE YOU ARE HAPPY WITH THIS

#User Editable Variables
# please edit the following variable if you haven't installed ffmpeg and x264 via my other script and the source for each app wasn't installed in the location below
INSTALL="/usr/local/src"
# location of log file
LOG=/var/log/ffmpegupreverse.log
# location of the script's lock file
LOCK="/var/run/ffmpegupreverse.pid"

########################################
# do not edit anything beyond this line, unless you know what you are doing
########################################

# first some error checking
set -o nounset
set -o errexit
set -o pipefail


###############
# list of all the functions in the script
###############

#maverick uninstall
maverick ()
{
apt-get remove x264 ffmpeg 
rm -rf $INSTALL/x264 >> $LOG
rm -rf $INSTALL/ffmpeg >> $LOG
}

#lucid uninstall
lucid ()
{
apt-get remove x264 ffmpeg 
rm -rf $INSTALL/x264 >> $LOG
rm -rf $INSTALL/ffmpeg >> $LOG
}

#karmic uninstall
karmic ()
{
apt-get remove x264 ffmpeg libtheora
rm $INSTALL/libtheora-1.1.1.tar.gz >> $LOG
rm -rf $INSTALL/libtheora-1.1.1 >> $LOG
rm -rf $INSTALL/x264 >> $LOG
rm -rf $INSTALL/ffmpeg >> $LOG
}

#jaunty uninstall
jaunty ()
{
apt-get remove x264 ffmpeg libopencore-amr libtheora
rm $INSTALL/libtheora-1.1.1.tar.gz >> $LOG
rm -rf $INSTALL/libtheora-1.1.1 >> $LOG
rm $INSTALL/opencore-amr-0.1.2.tar.gz >> $LOG
rm -rf $INSTALL/opencore-amr-0.1.2 >> $LOG
rm -rf $INSTALL/x264 >> $LOG
rm -rf $INSTALL/ffmpeg >> $LOG
}

#intrepid uninstall
intrepid ()
{
apt-get remove x264 ffmpeg libopencore-amr libtheora 
rm $INSTALL/libtheora-1.1.1.tar.gz >> $LOG
rm -rf $INSTALL/libtheora-1.1.1 >> $LOG
rm $INSTALL/opencore-amr-0.1.2.tar.gz >> $LOG
rm -rf $INSTALL/opencore-amr-0.1.2 >> $LOG
rm -rf $INSTALL/x264 >> $LOG
rm -rf $INSTALL/ffmpeg >> $LOG
}
 
#hardy uninstall
hardy ()
{
apt-get remove x264 ffmpeg libopencore-amr libtheora yasm 
rm $INSTALL/yasm-1.0.0.tar.gz >> $LOG
rm -rf $INSTALL/yasm-1.0.0 >> $LOG
rm $INSTALL/libtheora-1.1.1.tar.gz >> $LOG
rm -rf $INSTALL/libtheora-1.1.1 >> $LOG
rm $INSTALL/opencore-amr-0.1.2.tar.gz >> $LOG
rm -rf $INSTALL/opencore-amr-0.1.2 >> $LOG
rm -rf $INSTALL/x264 >> $LOG
rm -rf $INSTALL/ffmpeg >> $LOG
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
	echo $1
	echo $@
	exit 1
}
#this script must be run as root, so lets check that
if [ "$(id -u)" != "0" ]; then
   echo "Exiting. This script must be run as root" 1>&2
   exit 1
fi


#first, lets warn the user use of this script requires some common sense and may mess things up
echo "WARNING, this script removes the packages built by my ffmpegup.sh."
echo
echo "WARNING, this may invovle the removal of packages you may have had previously on your system."
echo
echo "Only proceed if you want to COMPLETELY remove ALL these packages."
read -p "Continue (y/n)?"
[ "$REPLY" == y ] || die "Exiting, nothing has been removed or undone."
echo

#next, lets find out what version of Ubuntu we are running and check it
DISTRO=( $(cat /etc/lsb-release | grep CODE | cut -c 18-) )
OKDISTRO="hardy intrepid jaunty karmic lucid maverick"

if [[ ! $(grep $DISTRO <<< $OKDISTRO) ]]; then
  die "Exiting. Your distro is not supported, sorry.";
fi

read -p "You are running Ubuntu $DISTRO, is this correct (y/n)?"
[ "$REPLY" == y ] || die "Sorry, I think you are using a different distro, exiting to be safe."
echo


# check that the default place to download to and log file location is ok
echo "Is this the location you chose when you ran ffmpegup.sh or fffmpegin.sh?:"
read -p ""$INSTALL" (y/n)?"
[ "$REPLY" == y ] || die "Exiting. Please edit the script changing the INSTALL variable to the location of your choice."
echo

echo "This script logs to:"
echo "$LOG"
read -p "Is this ok (y/n)?"
[ "$REPLY" == y ] || die "Exiting. Please edit the script changing the LOG variable to the location of your choice."
echo

# ok, already, last check before proceeding
echo "OK, we are ready to rumble."
read -p "Shall I proceed, remember, this musn't be stopped (y/n)?"
[ "$REPLY" == y ] || die "Exiting. Bye, did I come on too strong?."
echo

echo "Lets roll!"
echo "script started" > $LOG
echo "uninstalling everything"
echo "uninstalling everything" >> $LOG
$DISTRO || error "Sorry something went wrong, please check the $LOG file."
echo "That's it, all done."
echo "Exiting now, bye. Sorry you didn't like my other scripts :( "
exit
