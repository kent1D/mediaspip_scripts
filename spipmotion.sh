#!/bin/bash
# SPIPmotion : A shell program to convert multimedia files
# Version 0.3
#
# Dependancies :
#   * ffmpeg with libmp3lame support
#
# Credits prealables : aozeo - http://www.aozeo.com/blog/40-linux-convertir-videos-flv-ffmpeg-telephone-portable

VERSION="0.3.1"

################ LOCALISATION #####################
messageaide="
SPIPmotion v$VERSION

Utilisation : ./spipmotion arguments
ou arguments doit inclure le fichier source et le fichier de sortie et éventuellement :
* la taille de la video ex : --size 320x240
* le bitrate de la video ex : --bitrate 448kbs
* le nombre d'image par seconde ex : --fps 15
* le bitrate audio ex : --audiobitrate 64kbs
* la fréquence d'echantillonnage sonnore ex : --bitrate 22050
* le chemin vers l'executable ffmpeg (--p). /usr/local/bin/ffmpeg est la valeur par défaut.

Exemples :
./spipmotion.sh --e fichier-entree.avi --s fichier-sortie.flv --size 320x240 --bitrate 448 --fps 15 --audiobitrate 64kbs --audiofreq 22050 --p /usr/local/bin/ffmpeg
./spipmotion.sh --e fichier-entree.wav --s fichier-sortie.mp3 --audiobitrate 64 --audiofreq 22050

#########################################################################################
##  Ce programme recquiert une version de ffmpeg                                       ##
##        compilée avec le support libmp3lame                                          ##
## Voir http://technique.arscenic.org/compilation-de-logiciel/article/compiler-ffmpeg1 ##
#########################################################################################
"
		formatsortie="SPIPmotion : le fichier de sortie doit se terminer par une extension reconnue : flv flac ogg ogv oga mp3 mp4 mov m4v webm"
		mauvaisarg="SPIPmotion : argument ${1} non reconnu
Pour visualiser le manuel de spipmotion, faîtes : \"./spipmotion --help\""
		pasfichierentree="SPIPmotion : aucun fichier source n'a été spécifié
Pour visualiser le manuel de spipmotion, faîtes : \"./spipmotion --help\""
		pasfichiersortie="SPIPmotion : aucun fichier de sortie n'a été spécifié
Pour visualiser le manuel de spipmotion, faîtes : \"./spipmotion --help\""
		assemblage="Conversion en .flv"
		titredejala="Fichier de sortie existant"
		textedejala="Attention, le fichier de sortie que vous avez spécifié existe déjà.
Voulez-vous l'écraser ?
Si non, le fichier déjà présent sera renommé."
		oui="oui"
		non="non"
		succes="Succès ! Le fichier a bien été converti !"

#################################################

################ ARGUMENTS ######################

FORCE="false";
while test -n "${1}"; do
	case "${1}" in
		--help|-h) echo "$messageaide";
		exit 0;;
		--version|-v) echo "SPIPmotion v. "${VERSION}"";
		exit 0;;
		--force|-f) FORCE="true"
		shift;;
		--e) entree="${2}"
		shift;;
		--s) sortie="${2}"
			case "$sortie" in
			*".mp3"|*".flac"|*".flv"|*".mp4"|*".ogg"*|".oga"|*".ogv"|*".m4v"|*".webm");;
			*) echo "$formatsortie";
			exit 1;;
			esac
		shift;;
		--pass) pass="-pass ${2}"
		shift;;
		--size) size="-s ${2}"
		shift;;
		--bitrate) bitrate="-vb ${2}.k"
		shift;;
		--acodec) acodec="-acodec ${2}"
		shift;;
		--vcodec) vcodec="-vcodec ${2}"
		shift;;
		--params_supp) params_sup=" ${2}"
		shift;;
		--audiobitrate) audiobitrate_quality="-ab ${2}.k"
		shift;;
		--audioquality) audiobitrate_quality="-aq ${2}"
		shift;;
		--audiofreq) audiofreq="-ar ${2}"
		shift;;
		--fps) fps="-r ${2}"
		shift;;
		--ac) ac="-ac ${2}"
		shift;;
		--p) chemin="${2}"
		shift;;
		--fpre) fpre="-fpre ${2}"
		shift;;
	esac
	shift
done

########## TRAITEMENT DES ARGUMENTS ###############

case "$entree" in
  "") echo "$pasfichierentree"; exit 1;;
esac

case "$sortie" in
  "") "$sortie" = "$entree.flv"
esac

case "$chemin" in
  "") chemin="/usr/local/bin/ffmpeg"
esac

########### Arguments spécifiques aux videos

case "$size" in
  "") size="-s 320x240"
esac

case "$bitrate" in
  "") bitrate="-vb 448k"
esac

case "$fps" in
  "") fps="-r 15"
esac

case "$vcodec" in
	"libx264")
	case "$params_sup" in
  		"") params_sup="-vpre default" ;;
  	esac
  	shift;;
	"")
	case "$sortie" in
  		*".flv") vcodec="-vcodec flv" ;;
  		*".ogg"|*".ogv") vcodec="-vcodec libtheora" ;;
  	esac
  	shift;;
esac
########### SI LA SORTIE EXISTE DÉJÀ #############


if [ -e "$sortie" ] && [ ${FORCE} != "true" ]
	then
	PS3='> '
	echo "###############################################################"
	echo "$textedejala";
	LISTE=("[y] $oui" "[n] $non")  # liste de choix disponibles
	select CHOIX in "${LISTE[@]}" ; do
	    case $REPLY in
	        1|y)
	        rm $sortie
	        break
	        ;;
	        2|n)
	        mv $sortie $sortie-backup
	        break
	        ;;
	    esac
	done
fi

############# ON UTILISE FFMPEG ################

case "$sortie" in
  *".mp3"|*".flac"|*".ogg"|*".oga" )
  	echo "SPIPmotion v$VERSION

On encode un son
"
  	echo "nice -19 $chemin -i $entree $acodec $audiobitrate_quality $audiofreq $ac -y $sortie"
  	nice -19 "$chemin" -i $entree $acodec $audiobitrate_quality $audiofreq $ac -y $sortie ;;
  *".flv"|*".mp4"|*".ogv"|*".mov"|*".m4v"|*".webm" )
  	echo "SPIPmotion v$VERSION

On encode une video
"
  	echo "nice -19 $chemin -i $entree $acodec $audiobitrate_quality $ac $audiofreq $pass $fps $size $vcodec $bitrate $params_sup $fpre -y $sortie"
  	nice -19 $chemin -i $entree $acodec $audiobitrate_quality $ac $audiofreq $pass $fps $size $vcodec $bitrate $params_sup $fpre -y $sortie ;;
esac

exit $?