#!/bin/bash

## Archiver.sh Script

## Get device
device="/dev/"`cat /proc/sys/dev/cdrom/info |grep 'drive name'|cut -d':' -f 2|awk '{print $1}'`

## Get Block size of CD
blocksize=`isoinfo -d -i $device | grep "^Logical block size is:" | cut -d " " -f 5`
if test "$blocksize" = ""; then
        echo Device FATAL ERROR: Blank blocksize >&2
        exit
fi

## Get Block count of CD
blockcount=`isoinfo -d -i $device | grep "^Volume size is:" | cut -d " " -f 4`
if test "$blockcount" = ""; then
        echo Device FATAL ERROR: Blank blockcount >&2
        exit
fi

isoname=""
volumeid=`isoinfo -d -i $device | grep "^Volume id:" | cut -d " " -f 3`
if test "$volumeid" = ""; then
        echo Device FATAL ERROR: Blank Volume id >&2
        exit
else
   isoname="$volumeid.iso"
   echo Check if $isoname exist ...
   if test -f "$isoname"; then
     now=$(date '+%Y%m%d-%H%M%S')
     echo File $isoname exist, create $volumeid-$now.iso
     isoname="$volumeid-$now.iso"
   else
     echo File $isoname not exist, create $isoname
   fi
fi


usage()
{
cat <<EOF

usage: $0 options
-h      Show this message
-d      Report the Location of your Device
-e      Automatically eject
-m      Check your MD5Hash of CD against Image (Run AFTER making Image)
-l      Location and name of ISO Image (/path/to/image.iso)
-r      Rip CD to ISO image

Example 1: Report location of drive
archiver.sh -d


Example 2: Rip a CD to ISO
archiver.sh -l /path/to/isoimage.iso -r

Example 3: Check MD5Hash (Run AFTER ripping CD to ISO)
archiver.sh -l /path/to/isoimage.iso -m


EOF
}



while getopts "hdml:er" OPTION; do
  case $OPTION in
    h)
      usage
      exit 1
       ;;
    d)
      echo "Your CDrom is located on: $device" >&2
      ;;
    m)
      echo "Checking MD5Sum of CD and New ISO Image"
      md5cd=`dd if=$device bs=$blocksize count=$blockcount | md5sum` >&2
      md5iso=`cat $LFLAG | md5sum` >&2
      echo "CD MD5 is:" $md5cd
      echo "ISO MD5 is:" $md5iso
      ;;
    l)
     LFLAG="$OPTARG"
      ;;
    e)
     EFLAG="$OPTARG"
      ;;
    r)
     #dd if=$device bs=$blocksize count=$blockcount of=$LFLAG status=progress
     #echo "Archiving Complete.  ISO Image located at:"$LFLAG
      if test "$LFLAG" != ""; then
           dd if=$device bs=$blocksize count=$blockcount of=$LFLAG status=progress
           echo "Archiving Complete.  ISO Image located at:"$LFLAG
      else
           dd if=$device bs=$blocksize count=$blockcount of=$isoname status=progress
           echo "Archiving Complete.  ISO Image located at:"$isoname
      fi
      if test "$EFLAG"; then
	   eject
      fi
      ;;
  esac
done
