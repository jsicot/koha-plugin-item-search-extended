#!/bin/bash
DIRNAME=$(dirname $0);
cd $DIRNAME;

source ./package.sh;
TODAY=$(date +%Y-%m-%d);
KPZFILENAME=$PROJECTNAME-v$VERSION.kpz;
FILEPATHFULLDIST=dist/$FILEPATH/$FILENAME;

mkdir dist ;
cp -r Koha dist/. ;
sed -i -e "s/{VERSION}/$VERSION/g" $FILEPATHFULLDIST ;
sed -i -e "s/{UPDATE_DATE}/$TODAY/g" $FILEPATHFULLDIST ;
cd dist ;
zip -r ../kpz/$KPZFILENAME ./Koha ;
cd .. ;
rm -rf dist ;