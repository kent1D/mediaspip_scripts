#!/bin/bash
#
# creer_distrib.sh
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.0.1

if [ ! -r distrib_core.txt ];then
	echo "Erreur"
	exit 1
fi

VERSION_SPIP_DISTRIB="0.0.1"

CURRENT=$(pwd)

function distrib_core()
{
	echo "Récupération de SPIP"
	NOM=$(cat distrib_core.txt |grep "^NOM=" | tr "=" " " |awk '{ print $2 }');
	REPERTOIRE=$(cat distrib_core.txt |grep "^REP=" | tr "=" " " |awk '{ print $2 }');
	SOURCE=$(cat distrib_core.txt |grep "^SOURCE=" | tr "=" " " |awk '{ print $2 }');
	SOURCE=$(cat distrib_core.txt |grep "^LIB=" | tr "=" " " |awk '{ print $2 }');
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
		DEPOT=$(env LANG=C svn info --non-interactive | awk '/^URL:/ { print $2 }')
		# cas de changement de dépot
		if [ "$DEPOT" == "$SOURCE" ];then
			echo "Mise à jour des sources"
			svn up
		else
			echo "Switch de dépot"
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
	
	if [ "$LIB" == "oui" ] && [ ! -d lib ];then
		echo "Création du répertoire lib"
		mkdir -p lib
	fi
	
	cd $CURRENT
}

function read_line_svn(){
	echo "Mise à jour des sources de $TYPE"
	svn up $REP/$TYPE/*
	while read line
	do
		IFS=';' read -ra ADDR <<< "$line"
	
		if [ ! -z "${ADDR[1]}" ];then
			if [ -d "$REP/$TYPE/${ADDR[0]}/.svn" ];then
				DEPOT=$(env LANG=C svn info $REP/$TYPE/${ADDR[0]}/ --non-interactive | awk '/^URL:/ { print $2 }')
				# cas de changement de dépot
				if [ "$DEPOT" != "${ADDR[1]}" ];then
					echo "Switch de dépot"
					svn sw ${ADDR[1]} $REP/$TYPE/${ADDR[0]}
				fi
			else
				echo "Récupération du code de ${ADDR[0]}"
				svn co ${ADDR[1]} $REP/$TYPE/${ADDR[0]}
			fi
			svn info $REP/$TYPE/${ADDR[0]} > $REP/$TYPE/${ADDR[0]}/svn.revision
		fi
	done < distrib_"$TYPE".txt
}

function distrib_autres ()
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

function distrib_empaqueter ()
{
	zip -roq $NOM $REP -x \*/.svn\*	
}


function creer_distrib ()
{

	distrib_core
	
	echo
	echo "RECUPERATION DES EXTENSIONS"
	distrib_autres extensions
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

# Cas où l'on appelle directement le script
if [[ "$0" == *creer_distrib.sh ]];then

	while [[ $1 = -* ]]; do
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
	
fi