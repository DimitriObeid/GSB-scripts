 #!/usr/bin/env bash

 #***** Code *****
 # Fonction d'installation des logiciels via la commande "apt update".
 function mise_a_jour()
 {
  	soft_list="Liste de logiciels.txt"

 	#***** Code *****
 	if [ ! -f "$soft_list" ]; then
		echo >&2; echo "Le fichier contenant la liste des logiciels requis n'a pas été trouvé" >&2; echo >&2; exit 1
	else
		echo "Le fichier contenant la liste des logiciels requis a été trouvé dans le dossier $(pwd)"

                if sudo apt update; then
                        echo; echo "La mise à jour du cache d'APT a été effectuée avec succès"; echo
                else
                	echo >&2; echo "Impossible de faire la mise à jour du cache d'APT" >&2; echo >&2; exit 1
                fi

		while read paquet; do
			echo "Mise à jour du paquet << $paquet >>"

			if sudo apt upgrade "$paquet"; then echo; echo "Le paquet << $paquet >> a été mis à jour avec succès sur votre système";
	 		else { echo "Impossible de mettre à jour le paquet << $paquet >>" >&2; echo >&2; exit 1; }; fi
		done < "$soft_list"
	fi
 }


function init_tripwire()
{
	tripwire --init
	tripwire --check
}

function init_clamav()
{
	systemctl enable clamd@scan.service
	systemctl start clamd@scan.service
}


mise_a_jour

init_tripwire

init_clamav
