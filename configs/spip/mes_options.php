<?php
	if (!defined("_ECRIRE_INC_VERSION")) return;
	require _DIR_RACINE.'mutualisation/mutualiser.php';

	$site = $_SERVER['HTTP_HOST'];
	if ($site != $_SERVER['HTTP_HOST']) {
		include_spip('inc/headers');
		redirige_par_entete('http://'.$site.'/');
	}

	$quota_cache = 50;

	define ('_INSTALL_SITE_PREF', prefixe_mutualisation($site));
	define ('_INSTALL_SERVER_DB', 'mysql');
	define ('_INSTALL_HOST_DB', 'localhost');
	define ('_INSTALL_USER_DB', 'user');
	define ('_INSTALL_PASS_DB', 'pass');
	define ('_INSTALL_NAME_DB', 'mu_'._INSTALL_SITE_PREF);

	/* mettre en commentaire la ligne suivante si vous utilisez l'option table_prefixe plus bas dans la config */
	define ('_INSTALL_TABLE_PREFIX', 'spip');

	include_spip('inc/acces');
	if(!defined('_ACCESS_FILE_NAME')){
		define('_ACCESS_FILE_NAME', '.htaccess');
	}
	verifier_htaccess('config/');


	/*
	 * Creer automatiquement les users SQL (pg|mysql)
	 *
	 * Cela permet
	 * - d'avoir un utilisateur root possedant les droits
	 * de creation de bases (cet utilisateur possedant obligatoirement
	 * une base a son nom en PG - PG ne se connecte pas sans donner un nom de bdd)
	 * - de creer des utilisateurs sql automatiquement
	 * ne possedant que les droits d'administation
	 * de leur base de donnee qui sera creee
	 *
	 * Il faut remplacer alors
	 * _INSTALL_(USER|PASS)_DB par _INSTALL_(USER|PASS)_DB_ROOT
	 *
	 * et ajouter dans demarrer_site l'option
	 * 'creer_user_base' => true
	 *
	 * define ('_INSTALL_USER_DB_ROOT', 'root');
	 * define ('_INSTALL_PASS_DB_ROOT', 'pass_root');
	 */

	/*
	 * Creer les bases de donnees via un ping sur une URL (methode AlternC)
	 *
	 * Il suffit de renseigner l'option url_creer_base, en lui passant les bons parametres :
	 *
	 * 'url_creer_base' => 'http://localhost/admin/sql_doadd.php?username=user&password=pass_user&dbn='.prefixe_mutualisation($site)
	 */


	/*
	 * Transformer sur les pages publiques les url des images
	 * /sites/mon_site/IMG/* -> /IMG/*
	 * /sites/mon_site/local/* -> /local/*
	 *
	 * - Necessite le mod_rewrite (reecriture d'url) d'apache
	 * - Ne fonctionne qu'avec des mutualisations de nom de domaine
	 * ('http_host' : http://mon_site_mutu.tld)
	 * (donc pas avec une mutualisation de repertoire - http://site/mon_spip_mutu/)
	 *
	 * et ajouter dans demarrer_site l'option
	 * 'url_img_courtes' => true
	 *
	 * Il est possible de regenerer les fichiers .htaccess
	 * crees automatiquement dans /IMG et /local
	 * grace a ?var_mode=creer_htaccess_img
	 *
	 */

	/*
	 * Inscrire ici le nom du site d'administration du tableau de bord
	 * de la mutualisation (ou plusieurs, separes par des virgules)
	 * pour autoriser tous les sites, ne pas definir la constante ;
	 * Si le site maitre n'est pas dans sites/ mais a la racine, mettre ''
	 * et ajouter 'mutualisation' dans $dossier_squelettes
	 */
	define ('_SITES_ADMIN_MUTUALISATION', 'www.mondomaine.org');

	demarrer_site($site,
		array(
			'creer_site' => true,        	// Creer ou non le site s'il n'existe pas (defaut: false)
			'creer_base' => true,        	// Creer ou non la base de donnee si elle n'existe pas (false)
			'creer_user_base' => false,  	// Creer ou non un utilisateur pour la nouvelle base de donnee (false)
			'mail' => 'email@mondomaine.org', // Adresse mail pour recevoir un mail lors d'une creation de site mutualise ('')
			'code' => 'pass_mutu',			// Code d'activation de base
			'table_prefix' => false,		// Definir automatiquement le prefixe de table (false) ... mettre true si tous les sites dans la meme base
			'cookie_prefix' => true,		// Definir automatiquement le prefixe de cookie (false)
			'repertoire' => 'sites',		// Nom du repertoire contenant les sites mutualises ('sites')
			'url_img_courtes' => true,		// Utiliser la redirection des URL d'images courtes dans la partie publique (false)
											// /!\ il faut qu'apache ait le droit d'ecrire dans les dossiers IMG/ et local/ a la racine du site !
											// C'est la que la mutualisation va ecrire les regles de redirection automatiques pour les images de chaque site
			'utiliser_panel' => true, // Utiliser une table externe pour recuperer des identifiants ... (code, user, pass) permettant a un utilisateur d'installer le site (false)
			'annonce' => '', // Texte a afficher en bas du formulaire d'activation de la mutualisation
			//'url_creer_base' => 'http://localhost/admin/sql_doadd.php?username=user&password=pass_user&dbn='.prefixe_mutualisation($site), // Creer la base de donnees via une URL (methode AlternC)
			'url_hebergeur' => 'http://'._SITES_ADMIN_MUTUALISATION,
			'url_contact_hebergeur' => 'http://'._SITES_ADMIN_MUTUALISATION.'/spip.php?page=contact'
		)
	);

?>
