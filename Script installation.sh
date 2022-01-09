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

## DÉFINITION DES FONCTIONS DE DÉCORATION

# Dessiner une ligne avec un caractère
function DrawLine()
{
        echo -ne "$(tput setaf 6)"

        for _ in $(eval echo -e "{1..$__BU_MAIN_TXT_COLS}"); do
                echo -n "-"
        done

        echo -ne "$(tput sgr0)"

        return 0

}

# Fonction de création d'un séparateur d'étapes
function Separateur()
{
	#**** Paramètres ****
	p_msg="$1"

	#**** Code ****
	echo

        DrawLine
        echo "##> $p_msg"
        DrawLine

        echo; echo

        return 0
}




## DÉFINITION DES FONCTIONS UTILES

function tripwire_config()
{
	Separateur "CONFIGUARTION DE TRIPWIRE"

	homedir_list="$(ls "/home")"

	echo "PATH:/usr/sbin" > "/root/.bashrc"

	for user in "$homedir_list"; do
		homepath="/home/$user"

		echo "PATH:/usr/sbin" >> "$homepath/.bashrc"
	done

	# Entrez de nouveau votre "site passphrase"
	twadmin -m F -c "/etc/tripwire/tw.cfg" -S "/etc/tripwire/site.key" "/etc/tripwire/twcfg.txt"

        sed -i 's/REPORTLEVEL   =3/REPORTLEVEL   =4/' "/etc/tripwire/twcfg.txt"

	tripwire --init
	tripwire --check

	# lire le rapport
	# et verifier si des fichiers ont été modifiés
	# regarder les levels des fichiers pour voir ceux qui ont été modifiés.
}

# Mise en place d’un mécanisme de verrouillage automatique de session en cas de non-utilisation du poste pendant un temps donné pour éviter tout accès au poste des users pendant leurs absences devant leurs postes de travail
function set_autolock()
{
	Separateur "CONFIGURATION DU VERROUILLAGE DE L'ÉCRAN"

	# Mettre le temps de dconf write /org/gnome/desktop/session/idle-delay 600

	return 0
}

# Application de la règle de mot de passe :
# Longueur minimale 12 caractères, durée de vie : 90 jours, verrouillage de compte à 3 tentatives, durée de verrouillage 30 minutes
function set_passwd_rule()
{
	Separateur "MISE EN PLACE DES RÈGLES DE MOTS DE PASSE"

	sed -i 's/PASS_MAX_DAYS/#PASS_MAX_DAYS' /etc/logins.defs	# Durée de vie du MDP
       	sed -i 's/PASS_WARN_AGE/#PASS_WARN_AGE' /etc/logins.defs	# Message d'avertissement concernant le temps restant avant que la durée de vie maximale du MDP ne soit atteinte.

	echo "PASS_MAX_DAYS   90" >> /etc/logins.defs			# Durée de vie du MDP
	echo "PASS_WARN_AGE   5" >> /etc/logins.defs			# Message d'avertissement concernant le temps restant (en jours) avant que la durée de vie maximale du MDP ne soit atteinte.

	# "audit"	: Enregistre le nom de l'utilisateur dans le journal du système si l'utilisateur n'est pas trouvé
	# "deny=3"	: Nombre de fois (3 tentatives) que le MDP peut être retapé avant que le compte ne se verrouille
	# "unlock_time"	: Durée de verrouillage | Temps d'attente avant de pouvoir se connecter au compte après les trois tentatives (1 800 secondes = 30 minutes)

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

function create_system_users()
{
	Separateur "CRÉATION DES UTILISATEURS"

	#**** Paramètres ****
	local p_tableau_utilsateur=$1

	#**** Code ****
	for utilisateur in "${p_tableau_utilisateur[@]}"; do

                #**** Variables *****
                local GSB_user="$utilisateur"                           # Pour chaque utilisateur, on redéfinit la valeur de la variable "$GSB_user"
                local sha_tmp_file="/tmp/script-installation.tmp"       # Fichier temporaire où la clé générée est stockée.

		#**** Code ****
		# Si l'utilisateur n'existe pas
		if ! id -u "$utilisateur"; then
			echo "Création de l'utilisateur $utilisateur"; echo

			# Ajout de l'utilisateur
			adduser "$utilisateur"

			# Création du MDP de l'utilisateur
			echo "Entrez le mot de passe utilisateur"
			passwd "$username"

	                echo "Entrez le mot de passe GRUB de l'utilisateur $utilisateur (de préférence celui que vous avez tapé juste avant)"

                	grub-mkpasswd-pbkdf2 > "$sha_tmp_file"
                	# entrez mot de pase X2

                	echo

                	# Copier la clef SHA à partir de degrub
                	SHA_KEY="$(cat "$sha_tmp_file")"

                	# Création des utilisateurs, dans le fichier "/etc/grub.d/00_header"
                	echo ""                                 >> "/etc/grub.d/00_header"
                	echo "cat << EOF"                       >> "/etc/grub.d/00_header"
                	echo "set superusers=\"$GSB_user\""     >> "/etc/grub.d/00_header"
                	echo "password_pbkdf2 \"$GSB_user\" \"$SHA_KEY\""       >> "/etc/grub.d/00_header"
                	echo ">> EOF"

        		# Vérifier dans le fichier "/boot/grub/grub.cfg" si les lignes suivantes apparaissent (la valeur de la variable "$GSB_user" est le nom de l'utilisateur, "$SHA_KEY" celle de la clé générée).
        		# set superusers="$GSB_user"
	        	# password_pbkdf2 "$GSB_user" "$SHA_KEY"
		else
			echo "L'utilisateur $utilisateur existe déjà"; echo
		fi
	done

	return 0
}

# Fonction d'installation des logiciels via la commande "apt install".
function installation()
{
	Separateur "INSTALLATION DES LOGICIELS"

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

		while read -r paquet; do
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

# Appel de la fonction d'installation des logiciels
installation

# Appel de la fonction de création des utilisateurs
create_system_users "Admin" "GSB" "dimob"

# Appel de la fonction de création de mots de passe GRUB, pour sécuriser le GRUB tout en empêchant le démarrage du système d'exploitation sans mot de passe.
config_grub_passwd "Admin" "GSB" "dimob"

# Mise en place des règles de mot de passe pour chaque session.
set_passwd_rule

# Mise en place du verrouillage automatique de l'écran après un certain temps d'inactivité.
set_autolock

# Configuartion de Tripwire
tripwire_config
