#!/bin/bash
#
# mediaspip_spip_installation.sh
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.3.3
#
# Ce script installe MediaSPIP
# - SPIP
# - Les extensions obligatoires au bon fonctionnement
# - Les plugins compatibles si configuré comme tel
# - Les thèmes compatibles si configuré comme tel
# - Le plugin de mutualisation si configuré comme tel
# - Les répertoires sites/ (si dans un cas de mutu) et lib/
# - Le htaccess de SPIP
#
# Ce script se base sur les 3 fichiers du script de création de distribution (spip/creer_distrib.sh) :
# -* distrib_extensions.txt : qui donne la liste des extensions SPIP obligatoires
# -* distrib_plugins.txt : qui donne la liste des plugins SPIP facultatifs
# -* distrib_themes.txt : qui donne la liste des thèmes SPIP
#
# Mises à jour :
# Version 0.3.2 - On utilise les mêmes fichiers txt de spip/creer_distrib.sh pour télécharger les plugins, extensions et thèmes
# Version 0.3.3 - On fait marcher le script avec dash

# Fonction d'installation de SPIP et des extensions obligatoires de MediaSPIP au minimum
recuperer_svn()
{
	TYPE=$2
	while read line
	do
		PLUGIN=$(echo $line | awk 'BEGIN { FS = ";" }; { print $1 }')
		SVN=$(echo $line | awk 'BEGIN { FS = ";" }; { print $2 }')
		if [ ! -z "$SVN" ];then
			if [ -d $PLUGIN/.svn ];then
				DEPOT_FICHIER=$(env LANG=C svn info $SVN/ --non-interactive | awk '/^URL:/ { print $2 }')
				# cas de changement de dépot
				if [ "$DEPOT_FICHIER" != "$SVN" ];then
					NEW_DEPOT=$SVN
					echo $(eval_gettext 'Info $PLUGIN change depot $NEW_DEPOT')
					svn sw $SVN $PLUGIN 2>> $LOG >> $LOG
				fi
			else
				echo $(eval_gettext 'Info $TYPE telecharge $PLUGIN')
				svn co $SVN $PLUGIN 2>> $LOG >> $LOG
			fi
		fi
	done < $1
}

mediaspip_install()
{
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip

#	TYPES="ferme_full:ferme:minimal:full:none"

	# Installation de mediaSPIP
	if [ ! -d "$SPIP" ]; then
		echo $(eval_gettext "Info SPIP telechargement")
		mkdir -p $SPIP
		cd $SPIP
		svn co $SPIP_SVN ./ 2>> $LOG >> $LOG
	elif [ -d $SPIP/.svn ];then
		cd $SPIP
		DEPOT=$(env LANG=C svn info --non-interactive | awk '/^URL:/ { print $2 }')
		# cas de changement de dépot
		if [ "$DEPOT" = "$SPIP_SVN" ];then
			echo $(eval_gettext "Info SPIP maj")
			cd $SPIP
			svn up 2>> $LOG >> $LOG
		else
			echo $(eval_gettext 'Info SPIP change depot $SPIP_SVN')
			svn sw $SPIP_SVN ./ 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log") &
		fi
	# cas d'une simple mise à jour		
	else
		echo $(eval_gettext "Info SPIP maj")
		cd $SPIP
		svn up 2>> $LOG >> $LOG
	fi
	
	REVISIONSPIP=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo $(eval_gettext 'Info SPIP install revision $REVISIONSPIP')
	
	echo
	echo $(eval_gettext "Info SPIP extensions")
	
	cd $SPIP/extensions/

	FICHIER='spip/distrib_extensions.txt'
	if [ -r $CURRENT/spip/distrib_extensions.txt ];then
		recuperer_svn $CURRENT/$FICHIER extension
	else
		error $(eval_gettext 'Erreur fichier $FICHIER')
	fi
	
	cd $SPIP
	
	echo $(eval_gettext "Info SPIP extensions maj")
	echo
	svn up extensions/* 2>> $LOG >> $LOG
	
	# Si on est dans un type full on installe les plugins et thèmes dits compatibles
	# par défaut
	if [ $SPIP_TYPE = "ferme_full" -o  $SPIP_TYPE = "full" ]; then
		
		if [ ! -d themes ]; then
			mkdir -p $SPIP/themes
		fi
		
		cd $SPIP/themes
		
		echo $(eval_gettext "Info SPIP themes")
		FICHIER='spip/distrib_themes.txt'
		if [ -r $CURRENT/$FICHIER ];then
			recuperer_svn $CURRENT/$FICHIER theme
		else
			error $(eval_gettext 'Erreur fichier $FICHIER')
		fi
		
		cd $SPIP
		
		echo $(eval_gettext "Info SPIP themes maj")
		svn up themes/* 2>> $LOG >> $LOG
		
		echo 
		echo $(eval_gettext "Info SPIP plugins")
		if [ ! -d plugins ];then
			echo $(eval_gettext "Info SPIP install plugins")
			mkdir -p $SPIP/plugins 2>> $LOG >> $LOG
		else
			echo $(eval_gettext "Info SPIP maj plugins")
			svn up plugins/* 2>> $LOG >> $LOG
		fi
		
		cd plugins
		
		FICHIER='spip/distrib_plugins.txt'
		if [ -r $CURRENT/$FICHIER ];then
			recuperer_svn $CURRENT/$FICHIER plugin
		else
			error $(eval_gettext 'Erreur fichier $FICHIER')
		fi
		
		cd $SPIP
	fi
	
	chmod 755 config/ 2>> $LOG >> $LOG
	chmod 755 tmp/ 2>> $LOG >> $LOG
	chmod 755 local/ 2>> $LOG >> $LOG
	chmod 755 IMG/ 2>> $LOG >> $LOG
	
	if [ ! -d lib ];then
		echo
		echo $(eval_gettext "Info SPIP repertoire lib")
		mkdir lib && chmod 755 lib/ 2>> $LOG >> $LOG
	fi

	# Si on est dans un type mutu on :
	# - installe le plugin de mutualisation
	# - crée le répertoire site si non existant
	# - vide les caches de l'ensemble des sites
	# par défaut
	if [ $SPIP_TYPE = "ferme" ] || [ $SPIP_TYPE = "ferme_full" ];then
		if [ ! -d mutualisation ];then
			echo
			echo $(eval_gettext "Info SPIP install mutualisation")
			svn co svn://zone.spip.org/spip-zone/_plugins_/mutualisation 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		else
			echo
			echo $(eval_gettext "Info SPIP maj mutualisation")
			svn up mutualisation/  2>> $LOG >> /dev/null || error $(eval_gettext "Erreur installation regarde log")
		fi
		if [ ! -d sites ];then
			echo
			echo $(eval_gettext "Info SPIP repertoire sites")
			mkdir sites && chmod 755 sites/ 2>> $LOG >> $LOG
		else
			echo 
			echo $(eval_gettext "Info SPIP suppression cache css")
			rm -Rvf $SPIP/sites/*/local/cache-css/* 2>> $LOG >> $LOG
			echo $(eval_gettext "Info SPIP suppression cache js")
			rm -Rvf $SPIP/sites/*/local/cache-js/* 2>> $LOG >> $LOG
			echo $(eval_gettext "Info SPIP suppression cache html")
			rm -Rvf $SPIP/sites/*/tmp/cache/meta_cache.php 2>> $LOG >> $LOG
			echo $(eval_gettext "Info SPIP suppression cache plugins")
			rm -Rvf $SPIP/sites/*/tmp/cache/* 2>> $LOG >> $LOG
		fi
	# Sinon on ne vide que le cache du site courant
	else
		echo
		echo $(eval_gettext "Info SPIP suppression cache css")
		rm -Rvf $SPIP/local/cache-css/* 2>> $LOG >> $LOG
		echo $(eval_gettext "Info SPIP suppression cache js")
		rm -Rvf $SPIP/local/cache-js/* 2>> $LOG >> $LOG
		echo $(eval_gettext "Info SPIP suppression cache html")
		rm -Rvf $SPIP/tmp/cache/meta_cache.php 2>> $LOG >> $LOG
		echo $(eval_gettext "Info SPIP suppression cache plugins")
		rm -Rvf $SPIP/tmp/cache/* 2>> $LOG >> $LOG
	fi
	
	echo
	echo $(eval_gettext "Info SPIP copie htaccess")
	cp htaccess.txt .htaccess
	
	echo
	echo $(eval_gettext 'Info SPIP changement droits $SPIP_USER $SPIP_GROUP')
	chown -Rvf $SPIP_USER:$SPIP_GROUP $SPIP 2>> $LOG >> /dev/null || return 1
	
	echo
	echo_reussite "$(eval_gettext 'Info MediaSPIP installe')"
	
}