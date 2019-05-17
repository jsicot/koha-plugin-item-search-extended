DIRNAME=$(dirname $0);
cd $DIRNAME;

echo 'Définir le nom du projet :'
read NAME
if [ "$NAME" = "" ]; then
    >&2 echo "Erreur: Veuillez préciser un nom de projet"
    exit 1;
fi
IFS=' '
CLEANEDNAME="$(echo $NAME | iconv -f utf8 -t ascii//TRANSLIT)";
CLEANEDNAME="${CLEANEDNAME//[^a-zA-Z0-9]/ }"
read -ra ADDR <<< "$CLEANEDNAME"
for i in "${ADDR[@]}"; do
    PACKAGE="$PACKAGE${i^}"
done
echo "Définir le nom du package [$PACKAGE] :"
read INPACKAGE
PACKAGE=${INPACKAGE:-$PACKAGE}

if [[ $PACKAGE =~ [^a-zA-Z0-9]+ ]]; then
    >&2 echo "Erreur: Le nom du package ne doit contenir que des caractères alphanumériques"
    exit 1;
fi

PROJECT="${CLEANEDNAME//[ ]/-}"
PROJECT=${PROJECT,,}

echo "Définir le nom système du projet [$PROJECT] :"
read INPROJECT
PROJECT="koha-plugin-${INPROJECT:-$PROJECT}"

if [[ $PROJECT =~ [^a-z0-9-]+ ]]; then
    >&2 echo "Erreur: Le nom système du projet ne doit contenir que des lettres minuscules, des chiffres et des tirets"
    exit 1;
fi

echo "Definir la version de base [1.0] :"
read INVERSION
VERSION=${INVERSION:-1.0}

echo "Quelle version minimum de Koha est nécessaire [3.120000] :"
read INMIN_KOHA_VERSION
MIN_KOHA_VERSION=${INMIN_KOHA_VERSION:-18.110000}

GITNAME="$(git config --get user.name)" ;
echo "Qui est l'auteur du projet [$GITNAME] ?"
read AUTHOR
AUTHOR=${AUTHOR:-$GITNAME}
AUTHOR="${AUTHOR//\'/\\\\\\\'}"

echo "Décrire le projet :"
read INDESCR
DESCR="${INDESCR//\'/\\\\\\\'}"

echo "Voulez-vous pusher le dépot sur gitlab [Y/n] ?"
read PUSH
PUSH=${PUSH:-Y}

sed -i -e "s/{PROJECT}/$PROJECT/g" package.sh ;
sed -i -e "s/{PACKAGE}/$PACKAGE/g" package.sh ;
sed -i -e "s/{VERSION}/$VERSION/g" package.sh ;

source ./package.sh;
mv "$FILEPATH/{PACKAGE}.pm" "$FILEPATH/$FILENAME"

sed -i -e "s/{NAME}/$NAME/g" "projectREADME.md" ; 
sed -i -e "s/{DESCRIPTION}/$INDESCR/g" "projectREADME.md" ;

git mv -f projectREADME.md README.md;

TODAY=$(date +%Y-%m-%d);
NAME="${NAME//\'/\\\\\\\'}"

sed -i -e "s/{PACKAGE}/$PACKAGE/g" "$FILEPATH/$FILENAME" ;
sed -i -e "s/{NAME}/$NAME/g" "$FILEPATH/$FILENAME" ;
sed -i -e "s/{AUTHOR}/$AUTHOR/g" "$FILEPATH/$FILENAME" ;
sed -i -e "s/{CREATION_DATE}/$TODAY/g" "$FILEPATH/$FILENAME" ;
sed -i -e "s/{MIN_KOHA_VERSION}/$MIN_KOHA_VERSION/g" "$FILEPATH/$FILENAME" ;
sed -i -e "s/{DESCRIPTION}/$DESCR/g" "$FILEPATH/$FILENAME" ;

git remote set-url origin "git@gitlab.univ-rennes2.fr:applis-doc-plugins-koha/$PROJECT.git" ;
git add package.sh "$FILEPATH/{PACKAGE}.pm" "$FILEPATH/$FILENAME" "README.md";
git rm install.sh ;
git commit -m "Initialisation de $PROJECT" ;
if [ "$PUSH" = "Y" ]; then
    git push origin master ;
fi
