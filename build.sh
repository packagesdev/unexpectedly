#!/bin/sh

BASEDIR="$( dirname "$0" )"
cd "$BASEDIR"

ABSOLUTE_FOLDER_PATH=`pwd`
ABSOLUTE_BUILD_PATH="$ABSOLUTE_FOLDER_PATH"/distribution/build

echo "$ABSOLUTE_FOLDER_PATH"

## Create the build folder if needed

/bin/mkdir -p distribution/build

## Create the artifacts folder if needed

/bin/mkdir -p distribution/artifacts

# Retrieve the version

VERSION="1.0"

if [ -f distribution/Version ];
then

	VERSION=`cat distribution/Version`

fi

## Build the application

pushd app_unexpectedly

/usr/bin/xcrun agvtool next-version -all

/usr/bin/xcrun agvtool new-marketing-version $VERSION

/usr/bin/xcodebuild -project "app_unexpectedly.xcodeproj" clean build -configuration Release -scheme "app_unexpectedly" -derivedDataPath "$ABSOLUTE_BUILD_PATH" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH"

popd


## Create the disk image

pushd distribution

DISKIMAGE_NAME="Unexpectedly"

## Convert disk image template to read-write disk image

if [ -f build/"$DISKIMAGE_NAME"_rw.dmg ]
then 
	/bin/rm build/"$DISKIMAGE_NAME"_rw.dmg
fi

/usr/bin/hdiutil convert Template/Template_ro.dmg -format UDRW -o build/"$DISKIMAGE_NAME"_rw.dmg > /dev/null

## Mount the disk image

/usr/bin/hdiutil attach build/"$DISKIMAGE_NAME"_rw.dmg -mountpoint build/diskimage_rw > /dev/null

## Rename the disk image

if [ -f Version ];
then

	/usr/sbin/diskutil rename "$DISKIMAGE_NAME" "$DISKIMAGE_NAME $VERSION" 
fi

## Copy the ReadMe to the disk image and prevent edition

if [ -f "Documents/ReadMe.rtf" ]
then

	/usr/bin/sed '2 s/^/\\readonlydoc1/' <"Documents/ReadMe.rtf" > "build/diskimage_rw/ReadMe.rtf"

else

	echo "Missing ReadMe.rtf"
fi

## Copy the application to the disk image

if [ -d build/Unexpectedly.app ]
then

	/bin/cp -R build/Unexpectedly.app build/diskimage_rw/

else

	echo "Missing application"

fi

## Remove useless files for a disk image

/bin/rm "build/diskimage_rw/Desktop DB"
/bin/rm "build/diskimage_rw/Desktop DF"
/bin/rm -r build/diskimage_rw/.fseventsd

## Unmount the disk image

/usr/bin/hdiutil detach build/diskimage_rw > /dev/null

## Convert disk image to read-only

if [ -f artifacts/"$DISKIMAGE_NAME".dmg ]
then 
	/bin/rm artifacts/"$DISKIMAGE_NAME".dmg
fi

/usr/bin/hdiutil convert build/"$DISKIMAGE_NAME"_rw.dmg -format UDZO -o artifacts/"$DISKIMAGE_NAME".dmg > /dev/null

## Remove the temporary disk image

if [ -f build/"$DISKIMAGE_NAME"_rw.dmg ]
then 
	/bin/rm build/"$DISKIMAGE_NAME"_rw.dmg
fi

popd

exit 0
