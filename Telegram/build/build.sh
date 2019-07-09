#!/bin/bash

set -e
FullExecPath=$PWD
pushd `dirname $0` > /dev/null
FullScriptPath=`pwd`
popd > /dev/null

if [ ! -d "$FullScriptPath/../../../TelegramPrivate" ]; then
  echo ""
  echo "This script is for building the production version of Telegreat."
  echo ""
  echo "For building custom versions please visit the build instructions page at:"
  echo "https://github.com/Sea-n/tdesktop/#build-instructions"
  exit
fi

Error () {
  cd $FullExecPath
  echo "$1"
  exit 1
}

if [ ! -f "$FullScriptPath/target" ]; then
  Error "Build target not found!"
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
  BuildTarget="$line"
done < "$FullScriptPath/target"

while IFS='' read -r line || [[ -n "$line" ]]; do
  set $line
  eval $1="$2"
done < "$FullScriptPath/version"

VersionForPacker="$AppVersion"
if [ "$AlphaVersion" != "0" ]; then
  AppVersion="$AlphaVersion"
  AppVersionStrFull="${AppVersionStr}_${AlphaVersion}"
  AlphaBetaParam="-alpha $AlphaVersion"
  AlphaKeyFile="talpha_${AppVersion}_key"
elif [ "$BetaChannel" == "0" ]; then
  AppVersionStrFull="$AppVersionStr"
  AlphaBetaParam=''
else
  AppVersionStrFull="$AppVersionStr.beta"
  AlphaBetaParam='-beta'
fi

echo ""
HomePath="$FullScriptPath/.."
cd $HomePath

if [ "$BuildTarget" == "linux" ]; then
  echo "Building version $AppVersionStrFull for Linux 64bit.."
  UpdateFile="tlinuxupd$AppVersion"
  SetupFile="tsetup.$AppVersionStrFull.tar.xz"
  ReleasePath="$HomePath/../out/Release"
  BinaryName="Telegreat"
elif [ "$BuildTarget" == "linux32" ]; then
  echo "Building version $AppVersionStrFull for Linux 32bit.."
  UpdateFile="tlinux32upd$AppVersion"
  SetupFile="tsetup32.$AppVersionStrFull.tar.xz"
  ReleasePath="$HomePath/../out/Release"
  BinaryName="Telegreat"
elif [ "$BuildTarget" == "mac" ]; then
  echo "Building version $AppVersionStrFull for OS X 10.8+.."
  if [ "$AC_USERNAME" == "" ]; then
    AC_USERNAME="AC_USERNAME"
  fi
  UpdateFile="tmacupd$AppVersion"
  SetupFile="tsetup.$AppVersionStrFull.dmg"
  ReleasePath="$HomePath/../out/Release"
  BinaryName="Telegreat"
elif [ "$BuildTarget" == "mac32" ]; then
  echo "Building version $AppVersionStrFull for OS X 10.6 and 10.7.."
  UpdateFile="tmac32upd$AppVersion"
  SetupFile="tsetup32.$AppVersionStrFull.dmg"
  ReleasePath="$HomePath/../out/Release"
  BinaryName="Telegreat"
elif [ "$BuildTarget" == "macstore" ]; then
  if [ "$AlphaVersion" != "0" ]; then
    Error "Can't build macstore alpha version!"
  fi

  echo "Building version $AppVersionStrFull for Mac App Store.."
  ReleasePath="$HomePath/../out/Release"
  BinaryName="Telegreat"
else
  Error "Invalid target!"
fi

#if [ "$BuildTarget" == "linux" ] || [ "$BuildTarget" == "linux32" ] || [ "$BuildTarget" == "mac" ] || [ "$BuildTarget" == "mac32" ] || [ "$BuildTarget" == "macstore" ]; then
  if [ "$AlphaVersion" != "0" ]; then
    if [ -d "$ReleasePath/deploy/$AppVersionStrMajor/$AppVersionStrFull" ]; then
      Error "Deploy folder for version $AppVersionStrFull already exists!"
    fi
  else
    if [ -d "$ReleasePath/deploy/$AppVersionStrMajor/$AppVersionStr.alpha" ]; then
      Error "Deploy folder for version $AppVersionStr.alpha already exists!"
    fi

    if [ -d "$ReleasePath/deploy/$AppVersionStrMajor/$AppVersionStr.beta" ]; then
      Error "Deploy folder for version $AppVersionStr.beta already exists!"
    fi

    if [ -d "$ReleasePath/deploy/$AppVersionStrMajor/$AppVersionStr" ]; then
      Error "Deploy folder for version $AppVersionStr already exists!"
    fi

    if [ -f "$ReleasePath/$UpdateFile" ]; then
      Error "Update file for version $AppVersion already exists!"
    fi
  fi

  DeployPath="$ReleasePath/deploy/$AppVersionStrMajor/$AppVersionStrFull"
#fi

if [ "$BuildTarget" == "linux" ] || [ "$BuildTarget" == "linux32" ]; then

# DropboxSymbolsPath="/root/TBuild/symbols"
# if [ ! -d "$DropboxSymbolsPath" ]; then
#   Error "Dropbox path not found!"
# fi

  BackupPath="/home/sean/TBuild/backup/$AppVersionStrMajor/$AppVersionStrFull/t$BuildTarget"
  if [ ! -d "/home/sean/TBuild/backup" ]; then
    Error "Backup folder not found!"
  fi

  gyp/refresh.sh

  cd $ReleasePath
  make -j4
  echo "$BinaryName build complete!"

  if [ ! -f "$ReleasePath/$BinaryName" ]; then
    Error "$BinaryName not found!"
  fi

  BadCount=`objdump -T $ReleasePath/$BinaryName | grep GLIBC_2\.1[6-9] | wc -l`
  if [ "$BadCount" != "0" ]; then
    Error "Bad GLIBC usages found: $BadCount"
  fi

  BadCount=`objdump -T $ReleasePath/$BinaryName | grep GLIBC_2\.2[0-9] | wc -l`
  if [ "$BadCount" != "0" ]; then
    Error "Bad GLIBC usages found: $BadCount"
  fi

  BadCount=`objdump -T $ReleasePath/$BinaryName | grep GCC_4\.[3-9] | wc -l`
  if [ "$BadCount" != "0" ]; then
    Error "Bad GCC usages found: $BadCount"
  fi

  BadCount=`objdump -T $ReleasePath/$BinaryName | grep GCC_[5-9]\. | wc -l`
  if [ "$BadCount" != "0" ]; then
    Error "Bad GCC usages found: $BadCount"
  fi

  if [ ! -f "$ReleasePath/Updater" ]; then
    Error "Updater not found!"
  fi

  BadCount=`objdump -T $ReleasePath/Updater | grep GLIBC_2\.1[6-9] | wc -l`
  if [ "$BadCount" != "0" ]; then
    Error "Bad GLIBC usages found: $BadCount"
  fi

  BadCount=`objdump -T $ReleasePath/Updater | grep GLIBC_2\.2[0-9] | wc -l`
  if [ "$BadCount" != "0" ]; then
    Error "Bad GLIBC usages found: $BadCount"
  fi

  BadCount=`objdump -T $ReleasePath/Updater | grep GCC_4\.[3-9] | wc -l`
  if [ "$BadCount" != "0" ]; then
    Error "Bad GCC usages found: $BadCount"
  fi

  BadCount=`objdump -T $ReleasePath/Updater | grep GCC_[5-9]\. | wc -l`
  if [ "$BadCount" != "0" ]; then
    Error "Bad GCC usages found: $BadCount"
  fi

# echo "Dumping debug symbols.."
# "$HomePath/../../Libraries/breakpad/out/Default/dump_syms" "$ReleasePath/$BinaryName" > "$ReleasePath/$BinaryName.sym"
# echo "Done!"

  echo "Stripping the executable.."
  strip -s "$ReleasePath/$BinaryName"
  echo "Done!"

  echo "Removing RPATH.."
  chrpath -d "$ReleasePath/$BinaryName"
  echo "Done!"

  echo "Preparing version $AppVersionStrFull, executing Packer.."
  cd "$ReleasePath"
  "./Packer" -path "$BinaryName" -path Updater -version $VersionForPacker $AlphaBetaParam
  echo "Packer done!"

  if [ "$AlphaVersion" != "0" ]; then
    if [ ! -f "$ReleasePath/$AlphaKeyFile" ]; then
      Error "Alpha version key file not found!"
    fi

    while IFS='' read -r line || [[ -n "$line" ]]; do
      AlphaSignature="$line"
    done < "$ReleasePath/$AlphaKeyFile"

    UpdateFile="${UpdateFile}_${AlphaSignature}"
    SetupFile="talpha${AlphaVersion}_${AlphaSignature}.tar.xz"
  fi

# SymbolsHash=`head -n 1 "$ReleasePath/$BinaryName.sym" | awk -F " " 'END {print $4}'`
# echo "Copying $BinaryName.sym to $DropboxSymbolsPath/$BinaryName/$SymbolsHash"
# mkdir -p "$DropboxSymbolsPath/$BinaryName/$SymbolsHash"
# cp "$ReleasePath/$BinaryName.sym" "$DropboxSymbolsPath/$BinaryName/$SymbolsHash/"
# echo "Done!"

  if [ ! -d "$ReleasePath/deploy" ]; then
    mkdir "$ReleasePath/deploy"
  fi

  if [ ! -d "$ReleasePath/deploy/$AppVersionStrMajor" ]; then
    mkdir "$ReleasePath/deploy/$AppVersionStrMajor"
  fi

  echo "Copying $BinaryName, Updater and $UpdateFile to deploy/$AppVersionStrMajor/$AppVersionStrFull..";
  mkdir "$DeployPath"
  mkdir "$DeployPath/$BinaryName"
  cp "$ReleasePath/$BinaryName" "$DeployPath/$BinaryName/"
  cp "$ReleasePath/Updater" "$DeployPath/$BinaryName/"
  mv "$ReleasePath/$UpdateFile" "$DeployPath/"
  if [ "$AlphaVersion" != "0" ]; then
    mv "$ReleasePath/$AlphaKeyFile" "$DeployPath/"
  fi
  cd "$DeployPath"
  tar -cJvf "$SetupFile" "$BinaryName/"

  mkdir -p $BackupPath
  cp "$SetupFile" "$BackupPath/"
  cp "$UpdateFile" "$BackupPath/"
  if [ "$AlphaVersion" != "0" ]; then
    cp -v "$AlphaKeyFile" "$BackupPath/"
  fi
fi

if [ "$BuildTarget" == "mac" ] || [ "$BuildTarget" == "mac32" ] || [ "$BuildTarget" == "macstore" ]; then

# DropboxSymbolsPath="$HOME/Dropbox/Telegreat/symbols"
# if [ ! -d "$DropboxSymbolsPath" ]; then
#   Error "Dropbox path not found!"
# fi

  BackupPath="/Volumes/SEAN/Sean/TBuild/deploy/$AppVersionStrMajor/$AppVersionStrFull"
  if [ ! -d "/Volumes/SEAN/Sean/TBuild/deploy" ]; then
    Error "Backup path not found!"
  fi

  gyp/refresh.sh
  xcodebuild -project Telegreat.xcodeproj -alltargets -configuration Release build

  if [ ! -d "$ReleasePath/$BinaryName.app" ]; then
    Error "$BinaryName.app not found!"
  fi

  if [ ! -d "$ReleasePath/$BinaryName.app.dSYM" ]; then
    Error "$BinaryName.app.dSYM not found!"
  fi

  if [ "$BuildTarget" == "mac" ] || [ "$BuildTarget" == "mac32" ]; then
    if [ ! -f "$ReleasePath/$BinaryName.app/Contents/Frameworks/Updater" ]; then
      Error "Updater not found!"
    fi
    if [ ! -f "$ReleasePath/$BinaryName.app/Contents/Helpers/crashpad_handler" ]; then
      Error "crashpad_handler not found!"
    fi
  fi
  if [ "$BuildTarget" == "macstore" ]; then
    if [ ! -d "$ReleasePath/$BinaryName.app/Contents/Frameworks/Breakpad.framework" ]; then
      Error "Breakpad.framework not found!"
    fi
  fi

#   echo "Dumping debug symbols.."
#   "$HomePath/../../Libraries/breakpad/src/tools/mac/dump_syms/build/Release/dump_syms" "$ReleasePath/$BinaryName.app.dSYM" > "$ReleasePath/$BinaryName.sym" 2>/dev/null
#   echo "Done!"

  echo "Stripping the executable.."
  strip "$ReleasePath/$BinaryName.app/Contents/MacOS/$BinaryName"
  echo "Done!"

  echo "Signing the application.."
  if [ "$BuildTarget" == "mac" ] || [ "$BuildTarget" == "mac32" ]; then
:#  codesign --force --deep --timestamp --options runtime --sign "Mac Developer: Sean Wei (Sean Wei)" "$ReleasePath/$BinaryName.app" --entitlements "$HomePath/Telegram/Telegreat.entitlements"
  elif [ "$BuildTarget" == "macstore" ]; then
    codesign --force --deep --sign "3rd Party Mac Developer Application: TELEGRAM MESSENGER LLP (6N38VWS5BX)" "$ReleasePath/$BinaryName.app" --entitlements "$HomePath/Telegreat/Telegreat Desktop.entitlements"
    echo "Making an installer.."
	productbuild --sign "3rd Party Mac Developer Installer: Sean (3FPCM73V8N)" --component "$ReleasePath/$BinaryName.app" /Applications "$ReleasePath/$BinaryName.pkg"
  fi
  echo "Done!"

  AppUUID=`dwarfdump -u "$ReleasePath/$BinaryName.app/Contents/MacOS/$BinaryName" | awk -F " " '{print $2}'`
# DsymUUID=`dwarfdump -u "$ReleasePath/$BinaryName.app.dSYM" | awk -F " " '{print $2}'`
# if [ "$AppUUID" != "$DsymUUID" ]; then
#   Error "UUID of binary '$AppUUID' and dSYM '$DsymUUID' differ!"
# fi

  if [ ! -f "$ReleasePath/$BinaryName.app/Contents/Resources/Icon.icns" ]; then
    Error "Icon.icns not found in Resources!"
  fi

  if [ ! -f "$ReleasePath/$BinaryName.app/Contents/MacOS/$BinaryName" ]; then
    Error "$BinaryName not found in MacOS!"
  fi

# if [ ! -d "$ReleasePath/$BinaryName.app/Contents/_CodeSignature" ]; then
#   Error "$BinaryName signature not found!"
# fi

  if [ "$BuildTarget" == "mac" ] || [ "$BuildTarget" == "mac32" ]; then
    if [ ! -f "$ReleasePath/$BinaryName.app/Contents/Frameworks/Updater" ]; then
      Error "Updater not found in Frameworks!"
    fi
  elif [ "$BuildTarget" == "macstore" ]; then
    if [ ! -f "$ReleasePath/$BinaryName.pkg" ]; then
      Error "$BinaryName.pkg not found!"
    fi
  fi

# SymbolsHash=`head -n 1 "$ReleasePath/$BinaryName.sym" | awk -F " " 'END {print $4}'`
# echo "Copying $BinaryName.sym to $DropboxSymbolsPath/$BinaryName/$SymbolsHash"
# mkdir -p "$DropboxSymbolsPath/$BinaryName/$SymbolsHash"
# cp "$ReleasePath/$BinaryName.sym" "$DropboxSymbolsPath/$BinaryName/$SymbolsHash/"
# echo "Done!"

  if [ "$BuildTarget" == "mac" ] || [ "$BuildTarget" == "mac32" ]; then
    cd "$ReleasePath"
    if [ "$AlphaVersion" == "0" ]; then
      cp -f tsetup_template.dmg tsetup.temp.dmg
      TempDiskPath=`hdiutil attach -nobrowse -noautoopenrw -readwrite tsetup.temp.dmg | awk -F "\t" 'END {print $3}'`
      cp -R "./$BinaryName.app" "$TempDiskPath/"
      bless --folder "$TempDiskPath/" --openfolder "$TempDiskPath/"
      hdiutil detach "$TempDiskPath"
      hdiutil convert tsetup.temp.dmg -format UDZO -imagekey zlib-level=9 -ov -o "$SetupFile"
      rm tsetup.temp.dmg
    fi

    if [ "$AlphaVersion" != "0" ]; then
      "./Packer" -path "$BinaryName.app" -target "$BuildTarget" -version $VersionForPacker $AlphaBetaParam -alphakey
      echo "Packer done!"

      if [ ! -f "$ReleasePath/$AlphaKeyFile" ]; then
        Error "Alpha version key file not found!"
      fi

      while IFS='' read -r line || [[ -n "$line" ]]; do
        AlphaSignature="$line"
      done < "$ReleasePath/$AlphaKeyFile"

      UpdateFile="${UpdateFile}_${AlphaSignature}"
      SetupFile="talpha${AlphaVersion}_${AlphaSignature}.zip"

      rm -rf "$ReleasePath/AlphaTemp"
      mkdir "$ReleasePath/AlphaTemp"
      mkdir "$ReleasePath/AlphaTemp/$BinaryName"
      cp -r "$ReleasePath/$BinaryName.app" "$ReleasePath/AlphaTemp/$BinaryName/"
      cd "$ReleasePath/AlphaTemp"
      zip -r "$SetupFile" "$BinaryName"
      mv "$SetupFile" "$ReleasePath/"
      cd "$ReleasePath"
    fi
    if [ "$BuildTarget" == "mac" ]; then
      echo "Beginning notarization process."
      xcrun altool --notarize-app --primary-bundle-id "taipei.sean.Telegreat" --username "$AC_USERNAME" --password "@keychain:AC_PASSWORD" --file "$SetupFile" 2> request_uuid.txt
      while IFS='' read -r line || [[ -n "$line" ]]; do
        Prefix=$(echo $line | cut -d' ' -f 1)
        Value=$(echo $line | cut -d' ' -f 3)
        if [ "$Prefix" == "RequestUUID" ]; then
          RequestUUID=$Value
        fi
      done < "request_uuid.txt"
      if [ "$RequestUUID" == "" ]; then
        Error "Could not extract Request UUID. See request_uuid.txt for more information."
      fi
      echo "Request UUID: $RequestUUID"
      rm request_uuid.txt

      RequestStatus=
      LogFile=
      while [[ "$RequestStatus" == "" ]]; do
        sleep 5
        xcrun altool --notarization-info "$RequestUUID" --username "$AC_USERNAME" --password "@keychain:AC_PASSWORD" 2> request_result.txt
        while IFS='' read -r line || [[ -n "$line" ]]; do
          Prefix=$(echo $line | cut -d' ' -f 1)
          Value=$(echo $line | cut -d' ' -f 2)
          if [ "$Prefix" == "LogFileURL:" ]; then
            LogFile=$Value
          fi
          if [ "$Prefix" == "Status:" ]; then
            if [ "$Value" == "in" ]; then
              echo "In progress..."
            else
              RequestStatus=$Value
              echo "Status: $RequestStatus"
            fi
          fi
        done < "request_result.txt"
      done
      if [ "$RequestStatus" != "success" ]; then
        echo "Notarization problems, response:"
        cat request_result.txt
        if [ "$LogFile" != "" ]; then
          echo "Requesting log..."
          curl $LogFile
        fi
        Error "Notarization FAILED."
      fi
      rm request_result.txt

      if [ "$LogFile" != "" ]; then
        echo "Requesting log..."
        curl $LogFile > request_log.txt
      fi

      xcrun stapler staple "$ReleasePath/$BinaryName.app"

      if [ "$AlphaVersion" != "0" ]; then
        rm -rf "$ReleasePath/AlphaTemp"
        mkdir "$ReleasePath/AlphaTemp"
        mkdir "$ReleasePath/AlphaTemp/$BinaryName"
        cp -r "$ReleasePath/$BinaryName.app" "$ReleasePath/AlphaTemp/$BinaryName/"
        cd "$ReleasePath/AlphaTemp"
        zip -r "$SetupFile" "$BinaryName"
        mv "$SetupFile" "$ReleasePath/"
        cd "$ReleasePath"
        echo "Alpha archive re-created."
      else
        xcrun stapler staple "$ReleasePath/$SetupFile"
      fi
    fi

    "./Packer" -path "$BinaryName.app" -target "$BuildTarget" -version $VersionForPacker $AlphaBetaParam
    echo "Packer done!"
  fi

  if [ ! -d "$ReleasePath/deploy" ]; then
    mkdir "$ReleasePath/deploy"
  fi

  if [ ! -d "$ReleasePath/deploy/$AppVersionStrMajor" ]; then
    mkdir "$ReleasePath/deploy/$AppVersionStrMajor"
  fi

  if [ "$BuildTarget" == "mac" ] || [ "$BuildTarget" == "mac32" ]; then
    echo "Copying $BinaryName.app and $UpdateFile to deploy/$AppVersionStrMajor/$AppVersionStr..";
    mkdir "$DeployPath"
    mkdir "$DeployPath/$BinaryName"
    cp -r "$ReleasePath/$BinaryName.app" "$DeployPath/$BinaryName/"
    if [ "$AlphaVersion" != "0" ]; then
      mv "$ReleasePath/$AlphaKeyFile" "$DeployPath/"
    fi
#   mv "$ReleasePath/$BinaryName.app.dSYM" "$DeployPath/"
    rm "$ReleasePath/$BinaryName.app/Contents/MacOS/$BinaryName"
    rm "$ReleasePath/$BinaryName.app/Contents/Frameworks/Updater"
    rm "$ReleasePath/$BinaryName.app/Contents/Info.plist"
#   rm -rf "$ReleasePath/$BinaryName.app/Contents/_CodeSignature"
    mv "$ReleasePath/$UpdateFile" "$DeployPath/"
    mv "$ReleasePath/$SetupFile" "$DeployPath/"

    if [ "$BuildTarget" == "mac" ]; then
      mkdir -p "$BackupPath/tmac"
      cp "$DeployPath/$UpdateFile" "$BackupPath/tmac/"
      cp "$DeployPath/$SetupFile" "$BackupPath/tmac/"
      if [ "$AlphaVersion" != "0" ]; then
        cp -v "$DeployPath/$AlphaKeyFile" "$BackupPath/tmac/"
      fi
    fi
    if [ "$BuildTarget" == "mac32" ]; then
      mkdir -p "$BackupPath/tmac32"
      cp "$DeployPath/$UpdateFile" "$BackupPath/tmac32/"
      cp "$DeployPath/$SetupFile" "$BackupPath/tmac32/"
      if [ "$AlphaVersion" != "0" ]; then
        cp -v "$DeployPath/$AlphaKeyFile" "$BackupPath/tmac32/"
      fi
    fi
  elif [ "$BuildTarget" == "macstore" ]; then
    echo "Copying $BinaryName.app to deploy/$AppVersionStrMajor/$AppVersionStr..";
    mkdir "$DeployPath"
    cp -r "$ReleasePath/$BinaryName.app" "$DeployPath/"
    mv "$ReleasePath/$BinaryName.pkg" "$DeployPath/"
    mv "$ReleasePath/$BinaryName.app.dSYM" "$DeployPath/"
    rm "$ReleasePath/$BinaryName.app/Contents/MacOS/$BinaryName"
    rm "$ReleasePath/$BinaryName.app/Contents/Info.plist"
    rm -rf "$ReleasePath/$BinaryName.app/Contents/_CodeSignature"
  fi
fi

echo "Version $AppVersionStrFull is ready!";
echo -en "\007";
sleep 1;
echo -en "\007";
sleep 1;
echo -en "\007";

if [ "$BuildTarget" == "mac" ]; then
  if [ -f "$ReleasePath/request_log.txt" ]; then
    DisplayingLog=
    while IFS='' read -r line || [[ -n "$line" ]]; do
      if [ "$DisplayingLog" == "1" ]; then
        echo $line
      else
        Prefix=$(echo $line | cut -d' ' -f 1)
        Value=$(echo $line | cut -d' ' -f 2)
        if [ "$Prefix" == '"issues":' ]; then
          if [ "$Value" != "null" ]; then
            echo "NB! Notarization log issues:"
            echo $line
            DisplayingLog=1
          else
            DisplayingLog=0
          fi
        fi
      fi
    done < "$ReleasePath/request_log.txt"
    if [ "$DisplayingLog" != "0" ] && [ "$DisplayingLog" != "1" ]; then
      echo "NB! Notarization issues not found:"
      cat "$ReleasePath/request_log.txt"
    else
      rm "$ReleasePath/request_log.txt"
    fi
  else
    echo "NB! Notarization log not found :("
  fi
fi
