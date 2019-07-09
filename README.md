# Check Sudoc
## Description
This plugin uses micro webservices from SUDOC (Abes) to add some controls and alerts on records in the staff interface (check holdings sync with the sudoc, merged or duplicate or local records detection, etc).
## Déploiement
Pour déploier le plugin, executez le script `build.sh`
```
user$ bash build.sh
```
Il va générer une archive kpz dans le répertoire kpz. Vous n'avez plus qu'à l'uploader dans la section Plugin de votre instance Koha
## Changement de version
Pour incrémenter le numéro de version du plugin, modifiez la valeur `VERSION` fichier `package.sh` avant de générer le .kpz.
