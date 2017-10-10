#!/bin/bash

if [ -z "$4" ]
then
 echo "usage: $0 source-basefolder source-subfolder destination-basefolder backup-basefolder"
 exit 1
fi

if ( /usr/bin/pgrep "$0" > /dev/null )
then
 echo "$0 is running."
 exit 2
fi


GLOBAL_TIME_NOW=`/bin/date +%Y%m%d%H%M%S`
GLOBAL_FOLDER_BACKUP_BASE="$4"
GLOBAL_FOLDER_BACKUP_FULL="$GLOBAL_FOLDER_BACKUP_BASE/${GLOBAL_TIME_NOW:0:6}/${GLOBAL_TIME_NOW:0:8}/$GLOBAL_TIME_NOW"

GLOBAL_FOLDER_SOURCE_BASE="$1"
GLOBAL_FOLDER_SOURCE_SUB="$2"
GLOBAL_FOLDER_SOURCE_FULL="$GLOBAL_FOLDER_SOURCE_BASE/$GLOBAL_FOLDER_SOURCE_SUB"
GLOBAL_FOLDER_DESTINATION_BASE="$3"

GLOBAL_FILE_TEMP=`/bin/mktemp`

/bin/mkdir --parents "$GLOBAL_FOLDER_BACKUP_FULL/$GLOBAL_FOLDER_DESTINATION_BASE"


# Remount

if [ ! -e "$GLOBAL_FOLDER_SOURCE_FULL" ]
then
 echo "Umount $GLOBAL_FOLDER_SOURCE_FULL ($(/bin/date))"
 /bin/umount "$GLOBAL_FOLDER_SOURCE_FULL"
 echo "Mount $GLOBAL_FOLDER_SOURCE_FULL ($(/bin/date))"
 /bin/mount "$GLOBAL_FOLDER_SOURCE_FULL"
fi

echo -e "Sync report from $GLOBAL_FOLDER_SOURCE_FULL to $GLOBAL_FOLDER_DESTINATION_BASE ($(/bin/date))\n"
/usr/bin/rsync -n -ai --delete "$GLOBAL_FOLDER_SOURCE_FULL" "$GLOBAL_FOLDER_DESTINATION_BASE" > "$GLOBAL_FILE_TEMP"
/bin/cat "$GLOBAL_FILE_TEMP"

# Remount

if [ ! -e "$GLOBAL_FOLDER_SOURCE_FULL" ]
then
 echo "Umount $GLOBAL_FOLDER_SOURCE_FULL ($(/bin/date))"
 /bin/umount "$GLOBAL_FOLDER_SOURCE_FULL"
 echo "Mount $GLOBAL_FOLDER_SOURCE_FULL ($(/bin/date))"
 /bin/mount "$GLOBAL_FOLDER_SOURCE_FULL"
fi

echo -e "\n\nBacking up (before deleted) from $GLOBAL_FOLDER_DESTINATION_BASE ($(/bin/date))\n"
/bin/grep "^\\*deleting   $GLOBAL_FOLDER_SOURCE_SUB/.*[^/]$" "$GLOBAL_FILE_TEMP" |
 /usr/bin/cut -d ' ' -f '2-' | {
 while read GLOBAL_FILE_BACKUP
  do
  /bin/cp -pv --parents "$GLOBAL_FOLDER_DESTINATION_BASE/$GLOBAL_FILE_BACKUP" "$GLOBAL_FOLDER_BACKUP_FULL" | /bin/grep '^”'
 done
 }

echo -e "\n\nBacking up (before overwritten) from $GLOBAL_FOLDER_DESTINATION_BASE ($(/bin/date))\n"
/bin/grep "^>f[^+]\\{9\\} $GLOBAL_FOLDER_SOURCE_SUB/.*$" "$GLOBAL_FILE_TEMP" |
 /usr/bin/cut -d ' ' -f '2-' | {
 while read GLOBAL_FILE_BACKUP
  do
  /bin/cp -pv --parents "$GLOBAL_FOLDER_DESTINATION_BASE/$GLOBAL_FILE_BACKUP" "$GLOBAL_FOLDER_BACKUP_FULL" | /bin/grep '^”'
 done
 }

echo -e "\n\nDeleting from $GLOBAL_FOLDER_DESTINATION_BASE ($(/bin/date))\n"
/bin/grep "^\\*deleting   $GLOBAL_FOLDER_SOURCE_SUB/.*[^/]$" "$GLOBAL_FILE_TEMP" |
 /usr/bin/cut -d ' ' -f '2-' | {
 while read GLOBAL_FILE_DELETE
  do
  /bin/rm -v "$GLOBAL_FOLDER_DESTINATION_BASE/$GLOBAL_FILE_DELETE"
 done
 }

/bin/grep "^\\*deleting   $GLOBAL_FOLDER_SOURCE_SUB/.*/$" "$GLOBAL_FILE_TEMP" |
 /usr/bin/cut -d ' ' -f '2-' | {
 while read GLOBAL_FOLDER_DELETE
  do
  echo "$GLOBAL_FOLDER_DESTINATION_BASE/$GLOBAL_FOLDER_DELETE"
  /bin/rmdir "$GLOBAL_FOLDER_DESTINATION_BASE/$GLOBAL_FOLDER_DELETE"
 done
 }

echo -e "\n\nSyncing from $GLOBAL_FOLDER_SOURCE_FULL ($(/bin/date))\n"
/bin/grep "^.d+\\{9\\} $GLOBAL_FOLDER_SOURCE_SUB/.*$" "$GLOBAL_FILE_TEMP" |
 /usr/bin/cut -d ' ' -f '2-' | {
 while read GLOBAL_FOLDER_CREATE
  do
  echo "$GLOBAL_FOLDER_CREATE"
  /bin/mkdir "$GLOBAL_FOLDER_DESTINATION_BASE/$GLOBAL_FOLDER_CREATE"
 done
 }

/bin/grep "^\.d.\\{9\\} $GLOBAL_FOLDER_SOURCE_SUB/.*$" "$GLOBAL_FILE_TEMP" |
 /usr/bin/cut -d ' ' -f '2-' | {
 while read GLOBAL_FOLDER_COPY
  do
  echo "$GLOBAL_FOLDER_COPY"
  /bin/touch -r "$GLOBAL_FOLDER_SOURCE_BASE/$GLOBAL_FOLDER_COPY" "$GLOBAL_FOLDER_DESTINATION_BASE/$GLOBAL_FOLDER_COPY"
  /bin/chmod --reference "$GLOBAL_FOLDER_SOURCE_BASE/$GLOBAL_FOLDER_COPY" "$GLOBAL_FOLDER_DESTINATION_BASE/$GLOBAL_FOLDER_COPY"
  /bin/chown --reference "$GLOBAL_FOLDER_SOURCE_BASE/$GLOBAL_FOLDER_COPY" "$GLOBAL_FOLDER_DESTINATION_BASE/$GLOBAL_FOLDER_COPY"
 done
 }

/bin/grep "^.f.\\{9\\} $GLOBAL_FOLDER_SOURCE_SUB/.*$" "$GLOBAL_FILE_TEMP" |
 /usr/bin/cut -d ' ' -f '2-' |
 /usr/bin/rsync -av --files-from=- "$GLOBAL_FOLDER_SOURCE_BASE" "$GLOBAL_FOLDER_DESTINATION_BASE"


echo -e "\n\n"
/bin/df -h "$GLOBAL_FOLDER_DESTINATION_BASE"
/bin/rm "$GLOBAL_FILE_TEMP"
echo -e "\n\nExit ($(/bin/date))"
