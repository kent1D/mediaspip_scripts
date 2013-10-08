#!/bin/bash
#
# mediaspip_spip_installation.sh
# © 2011-2013 - kent1 (kent1@arscenic.info)
# Version 0.4.0
#
# Ce script installe MediaSPIP
# - SPIP
# - Les plugins-dist obligatoires au bon fonctionnement
# - Les plugins compatibles si configuré comme tel
# - Les thèmes compatibles si configuré comme tel
# - Le plugin de mutualisation si configuré comme tel
# - Les répertoires sites_ms/ (si dans un cas de mutu) et lib/
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
# Version 0.3.9 - Télécharger deux librairies supplémentaires (jquery-validate pour inscription3 et oAuth pour le plugin éponyme)


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
				DEPOT_FICHIER=$(env LANG=en_US.UTF-8 svn info $PLUGIN/ --non-interactive | awk '/^URL:/ { print $2 }')
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

# Fonction d'installation des librairies
verifier_librairie()
{
	ZIP=$(echo $1 | sed 's/.*lien=\"\([^"]*\)\".*/\1/g')
	DIR=$(echo $1 | sed 's/.*nom=\"\([^"]*\)\".*/\1/g')
	FILE=$(echo $ZIP | sed 's/.*\///g' | sed 's/%20/ /g')

	# Si le répertoire de la lib n'existe pas
	# On va dans lib
	if [ ! -d "lib/$DIR" ];then
		cd lib/ 2>> $LOG >> $LOG

		# Si le zip n'est pas là on le récupère
		if [ ! -e "$FILE" ];then
			wget "$ZIP" 2>> $LOG >> $LOG
		fi

		# On check quel est le mime-type du fichier
		MIME=`file --mime-type "$FILE" |awk 'BEGIN { FS = ":" } ; {print $2}' | tr -d ' '`
		# Si c'est un zip, on sait le dézipper
		if [ $MIME = 'application/zip' ]; then
			FIRST=`zipinfo -1 "$FILE" | head -1`
			LASTCHAR=$(echo $FIRST | tail -c 2)
			# Si le premier fichier listé dans le zip est le répetoire espéré
			# On dézip simplement le fichier zip récupéré
			if [ "$FIRST" = "$DIR"/ ];then
				unzip "$FILE" 2>> $LOG >> $LOG
			# Si le premier fichier listé dans le zip est un répertoire mais pas celui espéré
			# On dézip le fichier zip récupéré
			# On renomme le répertoire
			elif [ "$LASTCHAR" = "/" ];then
				unzip "$FILE" 2>> $LOG >> $LOG
				mv "$FIRST" "$DIR" 2>> $LOG >> $LOG
			# Sinon c'est que ce ne sont que des fichiers à la racine du zip
			# On dézip donc le fichier dans le répertoire espéré
			else
				unzip "$FILE" -d "$DIR" 2>> $LOG >> $LOG
			fi
			rm "$FILE" 2>> $LOG >> $LOG
		else
			echo $(eval_gettext "Info SPIP lib erreur fichier $FILE")
		fi

		if [ ! -d "$DIR" ]; then
			echo $(eval_gettext "Info SPIP lib erreur dezip $DIR")
		fi
		cd ..
	fi
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
		DEPOT=$(env LANG=en_US.UTF-8 svn info --non-interactive | awk '/^URL:/ { print $2 }')
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

	REVISIONSPIP=$(env LANG=en_US.UTF-8 svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo $(eval_gettext 'Info SPIP install revision $REVISIONSPIP')

	echo
	echo $(eval_gettext "Info SPIP extensions")

	if [ -d extensions ];then
		echo $(eval_gettext "Info SPIP supprimer ancien repertoire extensions")
		rm -Rvf extensions	2>> $LOG >> $LOG
	fi

	if [ -h config/ecran_securite.php ];then
		echo $(eval_gettext "Info SPIP supprimer ecran_securite lien symbolique")
		rm config/ecran_securite.php 2>> $LOG >> $LOG	
	fi

	if [ -d securite ];then
		echo $(eval_gettext "Info SPIP supprimer repertoire securite")
		rm -Rvf securite	2>> $LOG >> $LOG 	
	fi

	cd $SPIP/plugins-dist/

	FICHIER='spip/distrib_plugins-dist.txt'
	if [ -r $CURRENT/spip/distrib_plugins-dist.txt ];then
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

IFS="
"
	# Récupération des librairies
	echo
	echo $(eval_gettext "Info SPIP librairies")
	for line in ` grep -hr "<lib " plugins*/*/p*.xml 2> /dev/null`;do
		verifier_librairie	$line
	done

	# Si on est dans un type mutu on :
	# - installe le plugin de mutualisation
	# - on récupère les plugins spécifique à la mutu 
	# - crée le répertoire site_ms si non existant (pas sites car peut poser problème avec la rubrique sites)
	# - vide les caches de l'ensemble des sites
	# par défaut
	if [ $SPIP_TYPE = "ferme" ] || [ $SPIP_TYPE = "ferme_full" ];then
		# Récupération et / ou update du plugin de mutualisation
		if [ ! -d mutualisation ];then
			echo
			echo $(eval_gettext "Info SPIP install mutualisation")
			svn co svn://zone.spip.org/spip-zone/_plugins_/mutualisation 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		else
			echo
			echo $(eval_gettext "Info SPIP maj mutualisation")
			svn up mutualisation/  2>> $LOG >> /dev/null || error $(eval_gettext "Erreur installation regarde log")
		fi

		# Récupération et / ou update des plugins liés à la mutualisation
		if [ ! -d plugins-ferme ]; then
			mkdir -p $SPIP/plugins-ferme
		fi

		cd $SPIP/plugins-ferme

		echo $(eval_gettext "Info SPIP plugins ferme")
		FICHIER='spip/distrib_ferme.txt'
		if [ -r $CURRENT/$FICHIER ];then
			recuperer_svn $CURRENT/$FICHIER theme
		else
			error $(eval_gettext 'Erreur fichier $FICHIER')
		fi

		cd $SPIP

		echo $(eval_gettext "Info SPIP plugins ferme maj")
		svn up plugins-ferme/* 2>> $LOG >> $LOG

		# Création du répertoire sites_ms/ si non existant
		# Suppression des caches CSS / JS / PHP 
		# Suppression des vieux logs
		if [ ! -d sites_ms ];then
			echo
			echo $(eval_gettext "Info SPIP repertoire sites")
			mkdir sites_ms && chmod 755 sites_ms/ 2>> $LOG >> $LOG
		else
			echo 
			echo $(eval_gettext "Info SPIP suppression cache css")
			rm -Rvf $SPIP/sites_ms/*/local/cache-css/* 2>> $LOG >> $LOG
			echo $(eval_gettext "Info SPIP suppression cache js")
			rm -Rvf $SPIP/sites_ms/*/local/cache-js/* 2>> $LOG >> $LOG
			echo $(eval_gettext "Info SPIP suppression cache html")
			rm -Rvf $SPIP/sites_ms/*/tmp/meta_cache.php 2>> $LOG >> $LOG
			rm -Rvf $SPIP/sites_ms/*/tmp/plugin_xml_cache.gz 2>> $LOG >> $LOG
			echo $(eval_gettext "Info SPIP suppression cache plugins")
			rm -Rvf $SPIP/sites_ms/*/tmp/cache/* 2>> $LOG >> $LOG
			rm -Rvf $SPIP/sites_ms/*/tmp/log/*.log.* 2>> $LOG >> $LOG
		fi

		echo
		echo $(eval_gettext "Info SPIP copie mes_options.php et mes_options_personnalisation.php.txt")
		cp $CURRENT/configs/spip/mes_options.php config/
		cp $CURRENT/configs/spip/mes_options_personnalisation.php.txt config/

	# Sinon on ne vide que le cache du site courant
	else
		echo
		echo $(eval_gettext "Info SPIP suppression cache css")
		rm -Rvf $SPIP/local/cache-css/* 2>> $LOG >> $LOG
		echo $(eval_gettext "Info SPIP suppression cache js")
		rm -Rvf $SPIP/local/cache-js/* 2>> $LOG >> $LOG
		chmod 777 -Rvf $SPIP/local/ 2>> $LOG >> $LOG
		echo $(eval_gettext "Info SPIP suppression cache html")
		rm -Rvf $SPIP/tmp/cache/meta_cache.php 2>> $LOG >> $LOG
		echo $(eval_gettext "Info SPIP suppression cache plugins")
		rm -Rvf $SPIP/tmp/cache/* 2>> $LOG >> $LOG
		chmod 777 -Rvf $SPIP/tmp/cache/ 2>> $LOG >> $LOG
	fi

	# Rendre exécutable spipmotion.sh
	chmod +x plugins-dist/spipmotion/script_bash/*.sh

	echo
	echo $(eval_gettext "Info SPIP copie htaccess")
	if [ ! -f .htaccess ]; then
		cp htaccess.txt .htaccess
	fi

	echo
	echo $(eval_gettext 'Info SPIP changement droits $SPIP_USER $SPIP_GROUP')
	chown -Rvf $SPIP_USER:$SPIP_GROUP $SPIP 2>> $LOG >> /dev/null || return 1

	echo
	echo_reussite "$(eval_gettext 'Info MediaSPIP installe')"
}
