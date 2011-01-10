#!/bin/bash
#
# mediaspip_spip_installation.sh
# © 2010 - kent1 (kent1@arscenic.info)
# Version 0.2
#
# Ce script installe MediaSPIP
# - SPIP
# - Les extensions obligatoires au bon fonctionnement
# - Les plugins compatibles si configuré comme tel

#######
# Fonction d'installation de SPIP et des extensions obligatoires de MediaSPIP au minimum
#######

mediaspip_install(){
	TYPES=(ferme_full ferme minimal full none)

	# Installation de mediaSPIP
	if [ ! -d $SPIP/mediaspip ]; then
		echo "Téléchargement de SPIP"
		cd $SPIP
		svn co $SPIP_SVN mediaspip 2>> $LOG >> $LOG
	else 
		echo "Mise à jour de SPIP"
		cd $SPIP/mediaspip
		svn up 2>> $LOG >> $LOG
	fi
	
	cd $SPIP/mediaspip
	
	REVISIONSPIP=$(env LANG=C svn info --non-interactive | awk '/^Revision:/ { print $2 }') 2>> $LOG >> $LOG
	echo "SPIP est installé à la révision $REVISIONSPIP"
	
	echo
	echo "Installation des extensions de mediaSPIP"
	
	cd $SPIP/mediaspip/extensions/

	if [ ! -d cfg2_compat ]; then
		echo "Téléchargement du plugin cfg2_compat"
		svn co svn://zone.spip.org/spip-zone/_plugins_/cfg2/extensions/compat cfg2_compat 2>> $LOG >> $LOG
	fi
	if [ ! -d cfg2_core ]; then
		echo "Téléchargement du plugin cfg2_core"
		svn co svn://zone.spip.org/spip-zone/_plugins_/cfg2/core cfg2_core 2>> $LOG >> $LOG
	fi
	if [ ! -d cfg2_interface ]; then
		echo "Téléchargement du plugin cfg2_interface"
		svn co svn://zone.spip.org/spip-zone/_plugins_/cfg2/extensions/interface cfg2_interface 2>> $LOG >> $LOG
	fi
	if [ ! -d diogene ]; then
		echo "Téléchargement du plugin diogene"
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene  2>> $LOG >> $LOG
	fi
	if [ ! -d diogene_gerer_auteurs ]; then
		echo "Téléchargement du plugin diogene_gerer_auteurs"
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_gerer_auteurs  2>> $LOG >> $LOG
	fi
	if [ ! -d diogene_licence ]; then
		echo "Téléchargement du plugin diogene_licence"
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_licence  2>> $LOG >> $LOG
	fi
	if [ ! -d diogene_spipicious ]; then
		echo "Téléchargement du plugin diogene_spipicious"
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_spipicious  2>> $LOG >> $LOG
	fi
	if [ ! -d emballe_medias ]; then
		echo "Téléchargement du plugin emballe_medias"
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/import_video/emballe_medias  2>> $LOG >> $LOG
	fi
	if [ ! -d emballe_medias_spipmotion ]; then
		echo "Téléchargement du plugin emballe_medias_spipmotion"
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/import_video/emballe_medias_spipmotion  2>> $LOG >> $LOG
	fi
	if [ ! -d forum ]; then
		echo "Téléchargement du plugin forum"
		svn co svn://zone.spip.org/spip-zone/_core_/branches/spip-2.1/plugins/forum  2>> $LOG >> $LOG
	fi
	if [ ! -d html5 ]; then
		echo "Téléchargement du plugin html5"
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/html5 2>> $LOG >> $LOG
	fi
	if [ ! -d mediaspip_config ]; then
		echo "Téléchargement du plugin mediaspip_config"
		svn co http://svn.aires-de-confluxence.info/svn/squelettes_spip/mediaspip_config 2>> $LOG >> $LOG
	fi
	if [ ! -d mediaspip_core ]; then
		echo "Téléchargement du plugin mediaspip_core"
		svn co http://svn.aires-de-confluxence.info/svn/MediaSPIP/plugins/mediaspip_core 2>> $LOG >> $LOG
	fi
	if [ ! -d mediaspip_init ]; then
		echo "Téléchargement du plugin mediaspip_init"
		svn co http://svn.aires-de-confluxence.info/svn/MediaSPIP/plugins/mediaspip_init 2>> $LOG >> $LOG
	fi
	if [ ! -d saveauto ]; then
		echo "Téléchargement du plugin saveauto"
		svn co svn://zone.spip.org/spip-zone/_plugins_/saveauto/2.1 saveauto 2>> $LOG >> $LOG
	fi
	if [ ! -d swfupload ]; then
		echo "Téléchargement du plugin swfupload"
		svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/swfupload 2>> $LOG >> $LOG
	fi
	if [ ! -d zpip ]; then
		echo "Téléchargement du plugin zpip"
		svn co svn://zone.spip.org/spip-zone/_squelettes_/zpip 2>> $LOG >> $LOG
	fi
	
	extensions_normales=(afficher_objets ajaxforms auteurs_syndic contact crayons doc2img facteur fonctions_images getID3 job_queue jquery_ui licence menus nospam nuage palette pcltar polyhierarchie saisies selecteur_generique spip-bonux-2 spipicious_jquery spipmotion saisies step zen-garden zeroclipboard)
	for i in ${extensions_normales[@]}; do
    	if [ ! -d $i ]; then
    		echo "Téléchargement du plugin $i"
			svn co svn://zone.spip.org/spip-zone/_plugins_/$i 2>> $LOG >> $LOG
		fi
	done
	
	cd $SPIP/mediaspip
	
	if [ ! -d themes ]; then
		mkdir themes
	fi
	
	echo "Mise à jour des extensions de MediaSPIP"
	svn up extensions/* 2>> $LOG >> /dev/null
	
	cd themes
	
	if [ ! -d spipeo ]; then
		echo "Téléchargement du thème spipeo"
		svn co http://svn.aires-de-confluxence.info/svn/themes_spip/zpip/spipeo 2>> $LOG >> $LOG
	fi
	
	if [ ! -d brazil ]; then
		echo "Téléchargement du thème brazil"
		svn co http://svn.aires-de-confluxence.info/svn/themes_spip/zpip/brazil 2>> $LOG >> $LOG
	fi
	
	if [ ! -d arscenic ]; then
		echo "Téléchargement du thème arscenic"
		svn co http://svn.aires-de-confluxence.info/svn/themes_spip/zpip/arscenic 2>> $LOG >> $LOG
	fi
	
	cd $SPIP/mediaspip
	echo "Mise à jour des themes de MediaSPIP"
	svn up themes/* 2>> $LOG >> /dev/null
	
	TYPES_FULL=(ferme_full full)
	if in_array $SPIP_TYPE ${TYPES_FULL[@]};then
		if [ ! -d plugins ];then
			echo "Installation des plugins optionnels de MediaSPIP"
			mkdir -p $SPIP/mediaspip/plugins 2>> $LOG >> $LOG
		else
			echo "Mise à jour des plugins optionnels de MediaSPIP"
			svn up plugins/* 2>> $LOG >> $LOG
		fi
		cd plugins
		plugins_optionnels=(ancres_douces bigbrother compositions criteres_suivant_precedent fulltext google_analytics gravatar legendes mediabox mediatheque memoization metadonnees_photo microblog multilang notation notifications openid opensearch pages recommander socialtags sparkstats spip_piwik/spip_piwik_2_0 verifier)
		for i in ${plugins_optionnels[@]}; do
	    	if [ ! -d $i ]; then
	    		echo "Téléchargement du plugin $i"
				svn co svn://zone.spip.org/spip-zone/_plugins_/$i 2>> $LOG >> $LOG
			fi
		done
		if [ ! -d agenda ]; then
			echo "Téléchargement du plugin agenda"
			svn co svn://zone.spip.org/spip-zone/_plugins_/agenda/2_1_0 agenda 2>> $LOG >> $LOG
		fi
		if [ ! -d cextras2 ]; then
			echo "Téléchargement du plugin cextras2"
			svn co svn://zone.spip.org/spip-zone/_plugins_/champs_extras2/core cextras2 2>> $LOG >> $LOG
		fi
		if [ ! -d cextras2_interface ]; then
			echo "Téléchargement du plugin cextras2_interface"
			svn co svn://zone.spip.org/spip-zone/_plugins_/champs_extras2/extensions/interface cextras2_interface 2>> $LOG >> $LOG
		fi
		if [ ! -d diogene_geo ]; then
			echo "Téléchargement du plugin diogene_geo"
			svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/diogene_complements/diogene_geo diogene_geo 2>> $LOG >> $LOG
		fi
		if [ ! -d podcast ]; then
			echo "Téléchargement du plugin podcast"
			svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/podcast podcast 2>> $LOG >> $LOG
		fi
		if [ ! -d porte_plume_documents ]; then
			echo "Téléchargement du plugin porte_plume_documents"
			svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/porte_plume_documents porte_plume_documents 2>> $LOG >> $LOG
		fi
		if [ ! -d porte_plume_documents ]; then
			echo "Téléchargement du plugin porte_plume_documents"
			svn co http://svn.aires-de-confluxence.info/svn/plugins_spip/porte_plume_documents porte_plume_documents 2>> $LOG >> $LOG
		fi
		cd ..
	fi
	
	if in_array $SPIP_TYPE ${TYPES[@]};then
		if [ ! -d mutualisation ];then
			echo "Installation du plugin de mutualisation"
			svn co svn://zone.spip.org/spip-zone/_plugins_/mutualisation 2>> $LOG >> $LOG
		else
			echo "Mise à jour du plugin de mutualisation"
			svn up mutualisation/  2>> $LOG >> $LOG
		fi
	fi
	
	chown -Rvf $SPIP_USER:$SPIP_GROUP $SPIP/mediaspip 2>> $LOG >> $LOG
	
	echo "Les fichiers de MediaSPIP sont installés"
}