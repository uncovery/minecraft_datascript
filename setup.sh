#!/bin/bash

#Edit these according to your environment
FOLDER="/home/minecraft/server/mc_assets"
MY_VERSION="1.15.2"
OLD_VERSION="1.14.4"

#no more editing below needed
DP_PATH=$FOLDER/minecraft-data/data

# delete all in case we did this before
rm -rf $FOLDER/burger
rm -rf $FOLDER/burger-extractor
rm -rf $FOLDER/minecraft-assets
rm -rf $FOLDER/minecraft-data
rm -rf $FOLDER/minecraft-jar-extractor

# make a folder for the burger file
mkdir burger_json_target

# get the required repos
git clone https://github.com/mcdevs/burger.git
git clone https://github.com/PrismarineJS/burger-extractor.git
git clone https://github.com/rom1504/minecraft-assets.git
git clone https://github.com/PrismarineJS/minecraft-data.git
git clone https://github.com/PrismarineJS/minecraft-jar-extractor

cd $FOLDER/burger
# setup Burger
python3 setup.py build
python3 setup.py install

#download minecraft and create the JSON file
python3 munch.py --download $MY_VERSION --output $FOLDER/burger_json_target/1.15.2.json

cd $FOLDER/burger-extractor

# setup the extractor
npm install

#run the extractor
node ./src/index.js ../burger_json_target/$MY_VERSION.json $OLD_VERSION

# iterate the created files
FILE_ARRAY=()
for new_file in "$FOLDER/burger-extractor/out"/*
do
    # processing one file, moving it to the target
    mv $new_file $FOLDER/minecraft-data/data/pc/$MY_VERSION/

    # get the filename from the path
    xbase=${new_file##*/}
    # strip the extention
    xpref=${xbase%.*}
    # create a string for the JSON object and add it to an array
    FILE_ARRAY+=("\"${xpref}\": \"pc/$MY_VERSION\"")
done

# iterate the array and add to string with trailing comma, except the last
for ((i=0;i< (${#FILE_ARRAY[@]} - 1);i++)) {
    JQ_STRING+="${FILE_ARRAY[$i]},"
}

# add the last element without the trailing comma
JQ_STRING="${JQ_STRING}${FILE_ARRAY[$i]}"

# parse the JSON in dataPaths.json and write a new file with the result
# comment: I tried to directly write the result to dataPaths.json but failed, hence the detour via tmp.json
cat $DP_PATH/dataPaths.json | jq '.pc."'"${MY_VERSION}"'" += {'"${JQ_STRING}"'}' > $DP_PATH/tmp.json

# remove the old file
unlink  $DP_PATH/dataPaths.json

# write the temp file final destination
mv $DP_PATH/tmp.json  $DP_PATH/dataPaths.json

echo "done!"
