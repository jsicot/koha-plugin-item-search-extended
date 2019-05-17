# Initialisateur de plugin Koha
## Description
Koha plugin default permet de générer les fichiers minimum pour créer un plugin Koha ainsi qu'un script permettant de créer une archvie kpz
## Installation
Commencez par cloner ce dépot git
```
user$ git clone git@gitlab.univ-rennes2.fr:applis-doc-plugins-koha/koha-plugin-default.git
```
Puis executez le script `install.sh` et répondez au différentes questions posées par le script
```
user$ bash ./install.sh
Définir le nom du projet :
Hello world
Définir le nom du package [HelloWorld] :

Définir le nom système du projet [hello-world] :

Definir la version de base [1.0] :

Quelle version minimum de Koha est nécessaire [3.120000] :
18.11
Décrire le projet :
Pour dire bonjour au monde
rm 'install.sh'
[master eb124b9] Initialisation de koha-plugin-hello-world
 4 files changed, 8 insertions(+), 65 deletions(-)
 rename Koha/Plugin/Fr/UnivRennes2/{{PACKAGE}.pm => HelloWorld.pm} (81%)
 rename Koha/Plugin/Fr/UnivRennes2/{{PACKAGE} => HelloWorld}/.gitkeep (100%)
 delete mode 100644 install.sh
Counting objects: 21, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (13/13), done.
Writing objects: 100% (21/21), 3.37 KiB | 575.00 KiB/s, done.
Total 21 (delta 3), reused 0 (delta 0)
remote: 
remote: The private project applis-doc-plugins-koha/koha-plugin-hello-world was successfully created.
remote: 
remote: To configure the remote, run:
remote:   git remote add origin git@gitlab.univ-rennes2.fr:applis-doc-plugins-koha/koha-plugin-hello-world.git
remote: 
remote: To view the project, visit:
remote:   https://gitlab.univ-rennes2.fr/applis-doc-plugins-koha/koha-plugin-hello-world
remote: 
To gitlab.univ-rennes2.fr:applis-doc-plugins-koha/koha-plugin-hello-world.git
 * [new branch]      master -> master
```
Le script va ainsi préparer la classe de votre plugin ainsi que le fichier `package.sh` contenant les variables de déploiement
Il va aussi changer le dépot origin pour en créer un nouveau pour votre projet sur GitLab

Enfin il va préparer le `README.md` de votre projet
