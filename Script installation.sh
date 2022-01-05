#!/usr/bin/env bash

# ----------------------
# INFORMATIONS Du SCRIPT

# Nom           : Script installation.sh
# Description   : Ce script installe les logiciels et les configurations requises pour les PC de l'entreprise GSB tournant sous Debian.
# Auteur     	: Dimitri Obeid
# Version       : 1.0

# ----------------------


# ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; #

##################################### FICHIER D'INSTALLATION ######################################

#### DÉFINITION DES RESSOURCES NÉCESSAIRES À L'INSTALLATION ET À LA CONFIGURATION

## DÉFINITION DES FONCTIONS

function config_grub_passwd()
{
	#**** Variables *****
	SHA_KEY="$(grub-mkpasswd-pbkdf2)"
	sha_tmp_file="/tmp/script-installation.tmp"
	GSB_superuser="GSB-user"

	#**** Code *****

	grub-mkpasswd-pbkdf2 > "$sha_tmp_file"
	# entrez mot de pase X2

	# Copier la clef SHA à partir de degrub
	SHA_KEY="$(cat "$sha_tmp_file")"

	# puis vi  dans /etc/grub.d/00_header

	cat << EOF
	set superusers="$GSB_superuser"
	password_pbkdf2 "$GSB_superuser" "$SHA_KEY"
	EOF

	update-grub
	vi /boot/grub/grub.cfg

	verifier si les variables ont été mise à jour
	# set superusers="$GSB_superuser"
	# password_pbkdf2 "$GSB_superuser" "$SHA_KEY"

}

# Fonction d'installation des logiciels via la commande "apt install".
function installation()
{
	#***** Variables *****
	soft_list="Liste de logiciels.txt"

 	#***** Code *****
 	if [ ! -f "$soft_list" ]; then
		echo "Le fichier contenant la liste des logiciels requis n'a pas été trouvé"; exit 1
	else
		echo "Le fichier contenant la liste des logiciels requis a été trouvé dans le dossier $(pwd)"

		while read paquet; do
	 		echo "Installation du paquet << $paquet >>"
	 		if sudo apt install "$paquet"; then echo; echo "Le paquet << $paquet >> a été installé avec succès sur votre système";
	 		else { echo "Impossible d'installer le paquer << $paquet >>"; exit 1; }; fi
		done < "$soft_list"
	fi
}



# /////////////////////////////////////////////////////////////////////////////////////////////// #

#***** Code *****

# Vérification si le script est exécuté avec les privilèges du super utilisateur.
if [ "$EUID" -ne 0 ]; then
	echo >&2; echo "ATTENTION ! Vous devez exécuter ce script avec les privilèges du super-utilisateur" >&2; echo >&2; exit 1
fi

# Appel de la fonction d'installation
installation

# Appel de la fonction de création d'un super-utilisateur, pour sécuriser le GRUB tout en empêchant le démarrage du système d'exploitation sans mot de passe.
config_grub_passwd
