#!/bin/bash
#
# creer_distrib.sh
#
# Ce script sert à créer une distribution SPIP spécifique basée sur 4 fichiers :
# -* distrib_core.txt : qui donne le nom de la distribution, son répertoire temporaire, l'adresse svn du core à utiliser
# -* distrib_plugins-dist.txt : qui donne la liste des extensions SPIP obligatoires
# -* distrib_plugins.txt : qui donne la liste des plugins SPIP facultatifs
# -* distrib_themes.txt : qui donne la liste des thèmes SPIP
#
# cf : CHANGELOG.md

if [ ! -r distrib_core.txt ];then
	echo "Erreur, pas de fichier distrib_core.txt"
	exit 1
fi

VERSION_SPIP_DISTRIB="0.3-dev"

CURRENT=$(pwd)

distrib_core()
{
	echo "Récupération de SPIP"
	NOM=$(cat distrib_core.txt |grep "^NOM=" | tr "=" " " |awk '{ print $2 }');
	REP=$(cat distrib_core.txt |grep "^REP=" | tr "=" " " |awk '{ print $2 }');
	SOURCE=$(cat distrib_core.txt |grep "^SOURCE=" | tr "=" " " |awk '{ print $2 }');
	LIB=$(cat distrib_core.txt |grep "^LIB=" | tr "=" " " |awk '{ print $2 }');
	if [ -z "$SOURCE" ];then
		echo "Erreur source"
		exit 1
	fi
	
	if [ -z "$NOM" ];then
		echo "Erreur nom"
		exit 1
	fi
	
	if [ -z "$REP" ];then
		REP="$NOM"
	fi
	
	if [ ! -d "$REP" ];then
		echo "Création du répertoire $REP"
		mkdir -p $REP
	fi
	
	cd $REP
	
	if [ ! -d .svn ];then
		echo "Récupération des sources"
		svn co $SOURCE ./
	else
		DEPOT=$(env LC_MESSAGES=en_US svn info --non-interactive | awk '/^URL:/ { print $2 }')
		# cas de changement de dépot
		if [ "$DEPOT" = "$SOURCE" ];then
			echo "Mise à jour des sources"
			svn up
		else
			echo "Switch de dépot ($DEPOT != $SOURCE)"
			svn sw $SOURCE ./
		fi
	fi
	
	if [ ! -d themes ];then
		echo "Création du répertoire des thèmes"
		mkdir -p themes
	fi
	
	if [ ! -d plugins ];then
		echo "Création du répertoire des plugins"
		mkdir -p plugins
	fi
	
	if [ "$LIB" = "oui" ] && [ ! -d lib ];then
		echo "Création du répertoire lib"
		mkdir -p lib
	fi
	
	if [ -d extensions ];then
		echo "Suppression de l'ancien répertoire des extensions"
		rm - Rvf extensions	
	fi
	
	if [ -h config/ecran_securite.php ];then
		echo "Suppression de l'ancien ecran_securite qui était un lien symbolique"
		rm config/ecran_securite.php	
	fi
	cd $CURRENT
}

read_line_svn(){
	echo "Mise à jour des sources de $TYPE"
	svn up $REP/$TYPE/*
	while read line
	do
		PLUGIN=$(echo $line | awk 'BEGIN { FS = ";" }; { print $1 }')
		SVN=$(echo $line | awk 'BEGIN { FS = ";" }; { print $2 }')
		if [ ! -z "$SVN" ];then
			if [ -d "$REP/$TYPE/$PLUGIN/.svn" ];then
				DEPOT=$(env LC_MESSAGES=en_US svn info $REP/$TYPE/$PLUGIN/ --non-interactive | awk '/^URL:/ { print $2 }')
				# cas de changement de dépot
				if [ "$DEPOT" != "$SVN" ];then
					echo "Switch de dépot ($DEPOT != $SVN)"
					svn sw $SVN $REP/$TYPE/$PLUGIN > /dev/null
					if [ $? -ne 0 ] ; then
						echo "Le plugin a changé de serveur svn"
						rm -Rvf $REP/$TYPE/$PLUGIN
						echo "Récupération de la nouvelle version de $PLUGIN"
						svn co $SVN $REP/$TYPE/$PLUGIN
					fi
				fi
			else
				echo "Récupération du code de $PLUGIN"
				svn co $SVN $REP/$TYPE/$PLUGIN
			fi
			svn info $REP/$TYPE/$PLUGIN > $REP/$TYPE/$PLUGIN/svn.revision
		fi
	done < distrib_"$TYPE".txt
}

distrib_autres ()
{
	TYPE=$1
	if [ -z "$TYPE" ];then
		echo "Erreur"
	fi
	
	if [ -r distrib_"$TYPE".txt ];then
		read_line_svn
	else
		echo "Pas de $TYPE"
	fi
}

distrib_empaqueter ()
{
	zip -roq "$NOM" $REP -x \*/.svn\*	
}


creer_distrib ()
{
	distrib_core
	
	echo
	echo "RECUPERATION DES EXTENSIONS"
	distrib_autres plugins-dist
	echo
	
	echo
	echo "RECUPERATION DES PLUGINS"
	distrib_autres plugins
	echo
	
	echo
	echo "RECUPERATION DES THEMES"
	distrib_autres themes
	echo
	
	echo
	echo "CRÉATION DE L'ARCHIVE"
	distrib_empaqueter
	echo
}

case "$0" in
	*creer_distrib.sh) 
		while [ $# -gt 0 ]; do
			case $1 in
				--help|-h) HELP="Oué c'est l'aide mais vide"
				echo 
				echo "$HELP"
				echo
				exit 0;;
				--version|-v) VERSION_AFFICHER="Script de création de distribution version $VERSION_SPIP_DISTRIB"
				echo "$VERSION_AFFICHER" 
				exit 0;;
			esac
		done
		creer_distrib
esac
