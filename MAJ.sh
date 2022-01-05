 #!/usr/bin/env bash
 
 #***** Code *****
 # Fonction d'installation des logiciels via la commande "apt update".
 function mise_a_jour()
 {
  	soft_list="Liste de logiciels.txt"
 
 	#***** Code *****
 	if [ ! -f "$soft_list" ]; then
		echo "Le fichier contenant la liste des logiciels requis n'a pas été trouvé"; exit 1
	else
		echo "Le fichier contenant la liste des logiciels requis a été trouvé dans le dossier $(pwd)"

		while read paquet; do
			echo "Mise à jour du paquet << $paquet >>"
	 		if sudo apt update && sudo apt upgrade "$paquet"; then echo; echo "Le paquet << $paquet >> a été mis à jour avec succès sur votre système";
	 		else { echo "Impossible de mettre à jour le paquer << $paquet >>"; exit 1; }; fi
		done < "$soft_list"
	fi
 }
