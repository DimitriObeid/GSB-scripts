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

# Mise en place d’un mécanisme de verrouillage automatique de session en cas de non-utilisation du poste pendant un temps donné pour éviter tout accès au poste des users pendant leurs absences devant leurs postes de travail
function set_autolock()
{

	return 0
}

# Application de la règle de mot de passe :
# Longueur minimale 12 caractères, durée de vie : 90 jours, verrouillage de compte à 3 tentatives, durée de verrouillage 30 minutes
function set_passwd_rule()
{
#	sed -i 's/#PASS_MAX_DAYS   99999/PASS_MAX_DAYS   90/' /path/to/file	# Longueur minimale
#	sed -i 's/#PASS_MAX_DAYS   99999/PASS_MAX_DAYS   90/' /path/to/file	# Durée de vie du MDP
#       sed -i 's/#PASS_WARN_AGE   7/PASS_WARN_AGE   5/' /path/to/file		# Message d'avertissement concernant le temps restant avant que la durée de vie maximale du MDP ne soit atteinte.
#       sed -i 's/#PASS_MAX_DAYS   99999/PASS_MAX_DAYS   90/' /path/to/file	# Verrouillage du compte à 3 tentatives
#       sed -i 's/#PASS_MAX_DAYS   99999/PASS_MAX_DAYS   90/' /path/to/file	# Durée du verrouillage

	# "audit"	: Enregistre le nom de l'utilisateur dans le journal du système si l'utilisateur n'est pas trouvé
	# "deny=3"	: Nombre de fois (3 tentatives) que le MDP peut être retapé avant que le compte ne se verrouille
	# "unlock_time"	: Temps d'attente avant de pouvoir se connecter au compte après les trois tentatives (1 800 secondes = 30 minutes)

	# "minlen=12"	: Taille minimale du MDP
	# "difolk=3"	: Nombre minimum de caractères différents (ici 3 caractères différents) lors qu'un changement de mot passe
	# "lcredit=3" 	: Pour obliger à utiliser trois minuscules (lower)
	# "ucredit=3" 	: Pour obliger à utiliser trois majuscules (upper)
	# "dcredit=3" 	: Pour obliger à utiliser trois chiffres (digital)
	# "ocredit=3" 	: Pour obliger à utiliser trois caractères non-alphanumériques (others - caractères spéciaux)

	printf "\n\n\n\n" >> "/etc/pam.d/common-account"
	echo "auth    required       pam_faillock.so preauth silent audit deny=3 unlock_time=600" >> "/etc/pam.d/system-auth"

	echo "password  required  pam_cracklib.so audit deny=3 unlock_time=1800 retry=3 minlen=12 difok=3 lcredit=3 ucredit=3 dcredit=3 ocredit=3" >> "/etc/pam.d/common-account "

	return 0
}

function config_grub_passwd()
{
	#**** Paramètres ****
	p_tableau_utilisateurs=("$@")

	#**** Code *****
	for utilisateur in "${p_tableau_utilisateur[@]}"; do

	        #**** Variables *****
		local GSB_user="$utilisateur"				# Pour chaque utilisateur, on redéfinit la valeur de la variable "$GSB_user"
	        local sha_tmp_file="/tmp/script-installation.tmp"	# Fichier temporaire où la clé générée est stockée.
        	local heredoc_string="


		#**** Code ****
		grub-mkpasswd-pbkdf2 > "$sha_tmp_file"
		# entrez mot de pase X2

		# Copier la clef SHA à partir de degrub
		SHA_KEY="$(cat "$sha_tmp_file")"

		# Création des utilisateurs
                local heredoc_string="
cat << EOF
set superusers=\"$GSB_user\"
password_pbkdf2 \"$GSB_user\" \"$SHA_KEY\"
EOF
"


		# Puis dans "/etc/grub.d/00_header"
		echo "$heredoc_string" >> "/etc/grub.d/00_header"
		echo >> "/etc/grub.d/00_header" >> "/etc/grub.d/00_header"

	done

	update-grub

	# Vérifier dans le fichier "/boot/grub/grub.cfg" si les lignes suivantes apparaissent (la valeur de la variable "$GSB_user" est le nom de l'utilisateur, "$SHA_KEY" celle de la clé générée).
	# set superusers="$GSB_user"
	# password_pbkdf2 "$GSB_user" "$SHA_KEY"

	return 0
}

# Fonction d'installation des logiciels via la commande "apt install".
function installation()
{
	#***** Variables *****
	soft_list="Liste de logiciels.txt"

 	#***** Code *****
 	if [ ! -f "$soft_list" ]; then
		echo >&2; echo "Le fichier contenant la liste des logiciels requis n'a pas été trouvé" >&2; echo >&2; exit 1
	else
		echo "Le fichier contenant la liste des logiciels requis a été trouvé dans le dossier $(pwd)"; echo

                if sudo apt update; then
                        echo; echo "La mise à jour du cache d'APT a été effectuée avec succès"; echo
                else
                        echo >&2; echo "Impossible de faire la mise à jour du cache d'APT" >&2; echo >&2; exit 1
                fi

		while read paquet; do
	 		echo "Installation du paquet << $paquet >>"
	 		if sudo apt install -y "$paquet"; then echo; echo "Le paquet << $paquet >> a été installé avec succès sur votre système";
	 		else { echo "Impossible d'installer le paquer << $paquet >>"; exit 1; }; fi
		done < "$soft_list"
	fi

	return 0
}



# /////////////////////////////////////////////////////////////////////////////////////////////// #

#***** Code *****

# Vérification si le script est exécuté avec les privilèges du super utilisateur.
if [ "$EUID" -ne 0 ]; then
	echo >&2; echo "ATTENTION ! Vous devez exécuter ce script avec les privilèges du super-utilisateur" >&2; echo >&2; exit 1
fi

# Appel de la fonction d'installation
installation

# Appel de la fonction de création , pour sécuriser le GRUB tout en empêchant le démarrage du système d'exploitation sans mot de passe.
config_grub_passwd "Admin" "GSB" "Dimob"
