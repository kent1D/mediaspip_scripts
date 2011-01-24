#!/bin/bash
#
# mediaspip_spip_installation.sh
# © 2011 - kent1 (kent1@arscenic.info)
# Version 0.3.1
#
# Ce script installe MediaSPIP
# - SPIP
# - Les extensions obligatoires au bon fonctionnement
# - Les plugins compatibles si configuré comme tel
# - Les répertoires sites/ (si dans un cas de mutu) et lib/
# - Le htaccess de SPIP

# Fonction d'installation de SPIP et des extensions obligatoires de MediaSPIP au minimum
mediaspip_install(){
	export TEXTDOMAINDIR=$CURRENT/locale
	export TEXTDOMAIN=mediaspip

	TYPES=(ferme_full ferme minimal full none)

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
		if [ "$DEPOT" == "$SPIP_SVN" ];then
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

	if [ ! -d cfg2_compat ]; then
		i=cfg2_compat
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co svn://zone.spip.org/spip-zone/_plugins_/cfg2/extensions/compat cfg2_compat 2>> $LOG >> $LOG
	fi
	if [ ! -d cfg2_core ]; then
		i=cfg2_core
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co svn://zone.spip.org/spip-zone/_plugins_/cfg2/core cfg2_core 2>> $LOG >> $LOG
	fi
	if [ ! -d cfg2_interface ]; then
		i=cfg2_interface
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co svn://zone.spip.org/spip-zone/_plugins_/cfg2/extensions/interface cfg2_interface 2>> $LOG >> $LOG
	fi
	if [ ! -d diogene ]; then
		i=diogene
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene  2>> $LOG >> $LOG
	fi
	if [ ! -d diogene_gerer_auteurs ]; then
		i=diogene_gerer_auteurs
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_gerer_auteurs  2>> $LOG >> $LOG
	fi
	if [ ! -d diogene_licence ]; then
		i=diogene_licence
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_licence  2>> $LOG >> $LOG
	fi
	if [ ! -d diogene_spipicious ]; then
		i=diogene_spipicious
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_spipicious  2>> $LOG >> $LOG
	fi
	if [ ! -d emballe_medias ]; then
		i=emballe_medias
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/import_video/emballe_medias  2>> $LOG >> $LOG
	fi
	if [ ! -d emballe_medias_spipmotion ]; then
		i=emballe_medias_spipmotion
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/import_video/emballe_medias_spipmotion  2>> $LOG >> $LOG
	fi
	if [ ! -d forum ]; then
		i=forum
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co svn://zone.spip.org/spip-zone/_core_/branches/spip-2.1/plugins/forum  2>> $LOG >> $LOG
	fi
	if [ ! -d html5 ]; then
		i=html5
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/html5 2>> $LOG >> $LOG
	fi
	if [ ! -d mediaspip_config ]; then
		i=mediaspip_config
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/squelettes_spip/mediaspip_config 2>> $LOG >> $LOG
	fi
	if [ ! -d mediaspip_core ]; then
		i=mediaspip_core
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/MediaSPIP/plugins/mediaspip_core 2>> $LOG >> $LOG
	fi
	if [ ! -d mediaspip_init ]; then
		i=mediaspip_init
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/MediaSPIP/plugins/mediaspip_init 2>> $LOG >> $LOG
	fi
	if [ ! -d saveauto ]; then
		i=saveauto
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co svn://zone.spip.org/spip-zone/_plugins_/saveauto/2.1 saveauto 2>> $LOG >> $LOG
	fi
	if [ ! -d swfupload ]; then
		i=swfupload
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/swfupload 2>> $LOG >> $LOG
	fi
	if [ ! -d zpip ]; then
		i=zpip
		echo $(eval_gettext 'Info SPIP telecharge extension $i')
		svn co svn://zone.spip.org/spip-zone/_squelettes_/zpip 2>> $LOG >> $LOG
	fi
	
	extensions_normales=(afficher_objets ajaxforms auteurs_syndic contact crayons doc2img facteur fonctions_images getID3 job_queue jquery_ui licence menus nospam nuage palette pcltar polyhierarchie saisies selecteur_generique spip-bonux-2 spipicious_jquery spipmotion saisies step zen-garden zeroclipboard)
	for i in ${extensions_normales[@]}; do
    	if [ ! -d $i ]; then
    		echo $(eval_gettext 'Info SPIP telecharge extension $i')
    		#echo "Téléchargement de l'extension $i"
			svn co svn://zone.spip.org/spip-zone/_plugins_/$i 2>> $LOG >> $LOG
		fi
	done
	
	cd $SPIP
	
	echo $(eval_gettext "Info SPIP extensions maj")
	echo
	svn up extensions/* 2>> $LOG >> $LOG
	
	TYPES_FULL=(ferme_full full)
	# Si on est dans un type full on installe les plugins et thèmes dits compatibles
	# par défaut
	if in_array $SPIP_TYPE ${TYPES_FULL[@]};then
		
		if [ ! -d themes ]; then
			mkdir -p $SPIP/themes
		fi
		
		cd $SPIP/themes
		
		echo $(eval_gettext "Info SPIP themes")
		
		if [ ! -d spipeo ]; then
			i=SPIPeo
			echo $(eval_gettext 'Info SPIP telecharge theme $i')
			svn co http://svn.aires-de-confluxence.info/svn/themes_spip/zpip/spipeo 2>> $LOG >> $LOG
		fi
		
		if [ ! -d brazil ]; then
			i=Brazil
			echo $(eval_gettext 'Info SPIP telecharge theme $i')
			svn co http://svn.aires-de-confluxence.info/svn/themes_spip/zpip/brazil 2>> $LOG >> $LOG
		fi
		
		if [ ! -d arscenic ]; then
			i=Arscenic
			echo $(eval_gettext 'Info SPIP telecharge theme $i')
			svn co http://svn.aires-de-confluxence.info/svn/themes_spip/zpip/arscenic 2>> $LOG >> $LOG
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
		plugins_optionnels=(ancres_douces bigbrother compositions criteres_suivant_precedent fulltext google_analytics gravatar legendes mediabox mediatheque memoization metadonnees_photo microblog multilang notation notifications opensearch pages recommander socialtags sparkstats verifier)
		for i in ${plugins_optionnels[@]}; do
	    	if [ ! -d $i ]; then
	    		echo $(eval_gettext 'Info SPIP telecharge plugin $i')
				svn co svn://zone.spip.org/spip-zone/_plugins_/$i 2>> $LOG >> $LOG
			fi
		done
		if [ ! -d agenda ]; then
			i=agenda
			echo $(eval_gettext 'Info SPIP telecharge plugin $i')
			svn co svn://zone.spip.org/spip-zone/_plugins_/agenda/2_1_0 agenda 2>> $LOG >> $LOG
		fi
		if [ ! -d cextras2 ]; then
			i=cextras2
			echo $(eval_gettext 'Info SPIP telecharge plugin $i')
			svn co svn://zone.spip.org/spip-zone/_plugins_/champs_extras2/core cextras2 2>> $LOG >> $LOG
		fi
		if [ ! -d cextras2_interface ]; then
			i=cextras2_interface
			echo $(eval_gettext 'Info SPIP telecharge plugin $i')
			svn co svn://zone.spip.org/spip-zone/_plugins_/champs_extras2/extensions/interface cextras2_interface 2>> $LOG >> $LOG
		fi
		if [ ! -d diogene_geo ]; then
			i=diogene_geo
			echo $(eval_gettext 'Info SPIP telecharge plugin $i')
			svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_geo diogene_geo 2>> $LOG >> $LOG
		fi
		if [ ! -d podcast ]; then
			i=podcast
			echo $(eval_gettext 'Info SPIP telecharge plugin $i')
			svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/podcast podcast 2>> $LOG >> $LOG
		fi
		if [ ! -d porte_plume_documents ]; then
			i=porte_plume_documents
			echo $(eval_gettext 'Info SPIP telecharge plugin $i')
			svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/porte_plume_documents porte_plume_documents 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		fi
		if [ ! -d openid ]; then
			i=openid
			echo $(eval_gettext 'Info SPIP telecharge plugin $i')
			svn co svn://zone.spip.org/spip-zone/_plugins_/authentification/openid openid 2>> $LOG >> $LOG || error $(eval_gettext "Erreur installation regarde log")
		fi
		if [ ! -d spip_piwik_2_0 ]; then
			i=Piwik
			echo $(eval_gettext 'Info SPIP telecharge plugin $i')
			svn co svn://zone.spip.org/spip-zone/_plugins_/spip_piwik/spip_piwik_2_0 spip_piwik_2_0 2>> $LOG >> $LOG
		fi
		cd $SPIP
	fi
	
	if [ ! -d lib ];then
		echo
		echo $(eval_gettext "Info SPIP repertoire lib")
		mkdir lib && chmod 755 lib/ 2>> $LOG >> $LOG
	fi
	
	TYPES_MUTU=(ferme_full ferme)
	# Si on est dans un type mutu on :
	# - installe le plugin de mutualisation
	# - crée le répertoire site si non existant
	# - vide les caches de l'ensemble des sites
	# par défaut
	if in_array $SPIP_TYPE ${TYPES_MUTU[@]};then
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
	chown -Rvf $SPIP_USER:$SPIP_GROUP $SPIP 2>> $LOG >> /dev/null &
	wait $!
	
	echo
	echo_reussite $(eval_gettext "Info MediaSPIP installe")
	
}