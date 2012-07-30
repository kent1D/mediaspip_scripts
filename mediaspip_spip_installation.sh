#!/bin/bash
#
# mediaspip_spip_installation.sh
# © 2011-2012 - kent1 (kent1@arscenic.info)
# Version 0.3.8
#
# Ce script installe MediaSPIP
# - SPIP
# - Les plugins-dist obligatoires au bon fonctionnement
# - Les plugins compatibles si configuré comme tel
# - Les thèmes compatibles si configuré comme tel
# - Le plugin de mutualisation si configuré comme tel
# - Les répertoires sites/ (si dans un cas de mutu) et lib/
# - Le htaccess de SPIP
# - Le repertoire securite/ comprenant l'écran de sécurité, on crée un lien symbolique de securite/ecran_securite.php dans config/
#
# Ce script se base sur les 3 fichiers du script de création de distribution (spip/creer_distrib.sh) :
# -* distrib_extensions.txt : qui donne la liste des extensions SPIP obligatoires
# -* distrib_plugins.txt : qui donne la liste des plugins SPIP facultatifs
# -* distrib_themes.txt : qui donne la liste des thèmes SPIP
#
# Mises à jour :
# Version 0.3.2 - On utilise les mêmes fichiers txt de spip/creer_distrib.sh pour télécharger les plugins, extensions et thèmes
# Version 0.3.3 - On fait marcher le script avec dash
# Version 0.3.4 - On ajoute l'écran de sécurité
# Version 0.3.5 - On change la source du plugin zen-garden
# Version 0.3.6 - On change la source du plugin gis
# Version 0.3.7 - On règle un problème dans le switch des dépots
# Version 0.3.8 - LANG=C n'est pas disponible tout le temps ... on utilise LANG=en ... peut être plus fréquent

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
				DEPOT_FICHIER=$(env LANG=en svn info $PLUGIN/ --non-interactive | awk '/^URL:/ { print $2 }')
				# cas de changement de dépot
				if [ "$DEPOT_FICHIER" != "$SVN" ];then
					NEW_DEPOT=$SVN
					echo $(eval_gettext 'Info $PLUGIN change depot $NEW_DEPOT')
					svn sw $SVN $PLUGIN 2>> $LOG >> $LOG
					if [ $? -ne 0 ];then
						echo $(eval_gettext 'Info $PLUGIN change serveur $NEW_DEPOT')
						rm -Rvf $PLUGIN 2>> $LOG >> $LOG
						echo $(eval_gettext 'Info $TYPE telecharge $PLUGIN')
						svn co $PLUGIN 2>> $LOG >> $LOG
					fi
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
		DEPOT=$(env LANG=en svn info --non-interactive | awk '/^URL:/ { print $2 }')
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
	
	REVISIONSPIP=$(env LANG=en svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo $(eval_gettext 'Info SPIP install revision $REVISIONSPIP')
	
	echo
	echo $(eval_gettext "Info SPIP extensions")
	
	cd $SPIP/plugins-dist/

	FICHIER='spip/distrib_extensions.txt'
	if [ -r $CURRENT/spip/distrib_extensions.txt ];then
		recuperer_svn $CURRENT/$FICHIER extension
	else
		error $(eval_gettext 'Erreur fichier $FICHIER')
	fi
	
	cd $SPIP
	
	echo $(eval_gettext "Info SPIP extensions maj")
	echo
	svn up plugins-dist/* 2>> $LOG >> $LOG
	
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
	
	# Création du répertoire lib/
	if [ ! -d lib ];then
		echo
		echo $(eval_gettext "Info SPIP repertoire lib")
		mkdir lib && chmod 755 lib/ 2>> $LOG >> $LOG
	fi
	
	# On récupère les libs pour éviter d'avoir à la faire depuis SPIP
	if [ ! -d lib/jquery-mousewheel-3.0.6 ];then
		cd lib/ 2>> $LOG >> $LOG
		wget https://github.com/downloads/brandonaaron/jquery-mousewheel/jquery-mousewheel-3.0.6.zip 2>> $LOG >> $LOG
		unzip jquery-mousewheel-3.0.6.zip 2>> $LOG >> $LOG
		rm jquery-mousewheel-3.0.6.zip 2>> $LOG >> $LOG
		cd .. 2>> $LOG >> $LOG
	fi
	if [ ! -d lib/easyslider1.7 ];then
		cd lib/ 2>> $LOG >> $LOG
		wget http://cssglobe.com/lab/easyslider1.7/easyslider1.7.zip 2>> $LOG >> $LOG
		unzip easyslider1.7.zip 2>> $LOG >> $LOG
		rm easyslider1.7.zip 2>> $LOG >> $LOG
		rm -Rvf '__MACOSX' 2>> $LOG >> $LOG
		cd .. 2>> $LOG >> $LOG
	fi
	if [ ! -d lib/jquery.svg.package-1.4.4 ];then
		cd lib/ 2>> $LOG >> $LOG
		wget http://keith-wood.name/zip/jquery.svg.package-1.4.4.zip 2>> $LOG >> $LOG
		unzip jquery.svg.package-1.4.4.zip -d jquery.svg.package-1.4.4 2>> $LOG >> $LOG
		rm jquery.svg.package-1.4.4.zip 2>> $LOG >> $LOG
		cd .. 2>> $LOG >> $LOG
	fi
	if [ ! -d lib/farbtastic_1_3_1 ];then
		cd lib/ 2>> $LOG >> $LOG
		wget http://files.spip.org/contribs/farbtastic_1_3_1.zip 2>> $LOG >> $LOG
		unzip farbtastic_1_3_1.zip 2>> $LOG >> $LOG
		rm farbtastic_1_3_1.zip 2>> $LOG >> $LOG
		cd .. 2>> $LOG >> $LOG
	fi
	if [ ! -d lib/flot ];then
		cd lib/ 2>> $LOG >> $LOG
		wget http://flot.googlecode.com/files/flot-0.7.zip 2>> $LOG >> $LOG
		unzip flot-0.7.zip 2>> $LOG >> $LOG
		rm flot-0.7.zip 2>> $LOG >> $LOG
		cd .. 2>> $LOG >> $LOG
	fi
	if [ ! -d "lib/SWFUpload v2.2.0.1 Core" ];then
		cd lib/ 2>> $LOG >> $LOG
		wget http://swfupload.googlecode.com/files/SWFUpload%20v2.2.0.1%20Core.zip 2>> $LOG >> $LOG
		unzip 'SWFUpload v2.2.0.1 Core.zip' 2>> $LOG >> $LOG
		rm 'SWFUpload v2.2.0.1 Core.zip' 2>> $LOG >> $LOG
		cd .. 2>> $LOG >> $LOG
	fi
	if [ ! -d "lib/leaflet-gis-4.0.7" ];then
		cd lib/ 2>> $LOG >> $LOG
		wget https://github.com/downloads/brunob/Leaflet/leaflet-gis-4.0.7.zip 2>> $LOG >> $LOG
		unzip 'leaflet-gis-4.0.7.zip' 2>> $LOG >> $LOG
		rm 'leaflet-gis-4.0.7.zip' 2>> $LOG >> $LOG
		cd .. 2>> $LOG >> $LOG
	fi

	if [ ! -d securite ];then
		echo
		echo $(eval_gettext "Info SPIP install securite")
		svn co svn://zone.spip.org/spip-zone/_core_/securite 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		if [ -e config/ecran_securite.php ];then
			if [ ! -h config/ecran_securite.php ];then
				rm config/ecran_securite.php 2>> $LOG >> $LOG
				cd config
				ln -s ../securite/ecran_securite.php ./ 2>> $LOG >> $LOG
				cd ..
			fi
		else
			cd config
			ln -s ../securite/ecran_securite.php ./ 2>> $LOG >> $LOG
			cd ..
		fi
	else
		echo
		echo $(eval_gettext "Info SPIP maj securite")
		svn up securite/  2>> $LOG >> /dev/null || error $(eval_gettext "Erreur installation regarde log")
		if [ -e config/ecran_securite.php ];then
			if [ ! -h config/ecran_securite.php ];then
				rm config/ecran_securite.php 2>> $LOG >> $LOG
				cd config
				ln -s ../securite/ecran_securite.php ./ 2>> $LOG >> $LOG
				cd ..
			fi
		else
			cd config
			ln -s ../securite/ecran_securite.php ./ 2>> $LOG >> $LOG
			cd ..
		fi
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