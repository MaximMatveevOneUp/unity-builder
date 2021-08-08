#!/bin/sh

cacheFolderFull=$1
branch=$2
libraryFolderFull=$3
gitLFSDestinationFolder=$4
purgeRemoteBuilderCache=$5
LFS_ASSETS_HASH=$6

cacheFolderWithBranch="$cacheFolderFull/$branch"
lfsCacheFolder="$cacheFolderFull/$branch/lfs"
libraryCacheFolder="$cacheFolderFull/$branch/lib"

mkdir -p "$lfsCacheFolder"
mkdir -p "$libraryCacheFolder"

# if the unity git project has included the library delete it and echo a warning
if [ -d "$libraryFolderFull" ]; then
  rm -r "$libraryFolderFull"
  echo "!Warning!: The Unity library was included in the git repository (this isn't usually a good practice)"
fi

echo "Checking cache"

# Restore library cache
latestLibraryCacheFile=$(ls -t "$libraryCacheFolder" | grep .zip$ | head -1)

if [ ! -z "$latestLibraryCacheFile" ]; then
  echo "Library cache exists from build $latestLibraryCacheFile from $branch"
  mkdir -p "$libraryFolderFull"
  unzip "$libraryCacheFolder/$latestLibraryCacheFile" -d "$libraryFolderFull"
fi

echo "Checking cache for a cache match based on the combined large files hash ($lfsCacheFolder/$LFS_ASSETS_HASH.zip)"

if [ -f "$lfsCacheFolder/$LFS_ASSETS_HASH.zip" ]; then
  echo "Match found: using large file hash match $LFS_ASSETS_HASH.zip"
  latestLFSCacheFile="$LFS_ASSETS_HASH"
else
  latestLFSCacheFile=$(ls -t "$lfsCacheFolder" | grep .zip$ | head -1)
  echo "Match not found: using latest large file cache $latestLFSCacheFile"
fi


if [ ! -f "$lfsCacheFolder/$latestLFSCacheFile" ]; then
  echo "LFS cache exists from build $latestLFSCacheFile from $branch"
  rm -r "$gitLFSDestinationFolder"
  mkdir -p "$gitLFSDestinationFolder"
  unzip "$lfsCacheFolder/$latestLFSCacheFile" -d "$gitLFSDestinationFolder"
  echo "git LFS folder, (should not contain $latestLFSCacheFile)"
  ls -lh "$gitLFSDestinationFolder"
fi



echo ' '
echo "LFS cache for branch: $branch"
ls -lh "$lfsCacheFolder"
echo ' '
echo "Library cache for branch: $branch"
ls -lh "$libraryCacheFolder"
echo ' '
echo "Size of LFS cache folder for branch: $branch"
du -sch "$lfsCacheFolder"
echo ' '
echo "Size of Library cache folder for branch: $branch"
du -sch "$libraryCacheFolder"
echo ' '
echo "Size of cache folder for branch: $branch"
du -sch "$cacheFolderWithBranch"
echo ' '
echo 'Size of cache folder'
du -sch "$cacheFolderFull"
echo ' '
git lfs pull
echo 'pulled latest LFS files'
zip -r "$LFS_ASSETS_HASH.zip" "$gitLFSDestinationFolder"
cp "$LFS_ASSETS_HASH.zip" "$lfsCacheFolder"
echo "copied $LFS_ASSETS_HASH to $lfsCacheFolder"
echo ' '

# purge cache
if [ "$purgeRemoteBuilderCache" == "true" ]; then
  echo "purging the entire cache"
  rm -r "$cacheFolderFull"
  echo ' '
fi

