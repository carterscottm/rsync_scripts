#!/bin/bash
# ----------------------------------------------------------------------
# mikes handy rotating-filesystem-snapshot utility: yearly snapshots
# ----------------------------------------------------------------------
# intended to be run yearly as a cron job on the first of each month
# when hourly.4 contains the backup data from midnight
# ----------------------------------------------------------------------

unset PATH

CWD=`dirname $(realpath $0)`
source $CWD/backup.config;

# ------------- the script itself --------------------------------------
$TOUCH $DIAGNOSTICLOG;
$ECHO "*****************************************************************************" >> $DIAGNOSTICLOG;
$ECHO "$($DATE) - MONTHLY ROTATION STARTED" >> $DIAGNOSTICLOG;
# make sure we're running as root
if (( `$ID -u` != 0 )); then { $ECHO "$($DATE) - Sorry, must be root.  Exiting..."; >> $DIAGNOSTICLOG; exit 1; } fi

# attempt to remount the RW mount point as RW; else abort
$MOUNT -o remount,rw $MOUNT_DEVICE $SNAPSHOT_RW ;
if (( $? )); then
{
	$ECHO "$($DATE) - snapshot: could not remount $SNAPSHOT_RW readwrite" >> $DIAGNOSTICLOG;
	exit;
}
fi;


# step 1: delete the oldest snapshot, if it exists:
if [ -d $SNAPSHOT_RW/yearly.10 ] ; then		\
$RM -rf $SNAPSHOT_RW/yearly.10 ;			\
fi ;

# step 2: shift the middle snapshots(s) back by one, if they exist
if [ -d $SNAPSHOT_RW/yearly.9 ] ; then			\
$MV $SNAPSHOT_RW/yearly.9 $SNAPSHOT_RW/yearly.10 ;	\
fi;

if [ -d $SNAPSHOT_RW/yearly.8 ] ; then			\
$MV $SNAPSHOT_RW/yearly.8 $SNAPSHOT_RW/yearly.9;	\
fi;

if [ -d $SNAPSHOT_RW/yearly.7 ] ; then			\
$MV $SNAPSHOT_RW/yearly.7 $SNAPSHOT_RW/yearly.8 ;	\
fi;

if [ -d $SNAPSHOT_RW/yearly.6 ] ; then			\
$MV $SNAPSHOT_RW/yearly.6 $SNAPSHOT_RW/yearly.7 ;	\
fi;

if [ -d $SNAPSHOT_RW/yearly.5 ] ; then			\
$MV $SNAPSHOT_RW/yearly.5 $SNAPSHOT_RW/yearly.6 ;	\
fi;

if [ -d $SNAPSHOT_RW/yearly.4 ] ; then			\
$MV $SNAPSHOT_RW/yearly.4 $SNAPSHOT_RW/yearly.5;	\
fi;

if [ -d $SNAPSHOT_RW/yearly.3 ] ; then			\
$MV $SNAPSHOT_RW/yearly.3 $SNAPSHOT_RW/yearly.4 ;	\
fi;

if [ -d $SNAPSHOT_RW/yearly.2 ] ; then			\
$MV $SNAPSHOT_RW/yearly.2 $SNAPSHOT_RW/yearly.3 ;	\
fi;

if [ -d $SNAPSHOT_RW/yearly.1 ] ; then			\
$MV $SNAPSHOT_RW/yearly.1 $SNAPSHOT_RW/yearly.2 ;	\
fi;

if [ -d $SNAPSHOT_RW/yearly.0 ] ; then			\
$MV $SNAPSHOT_RW/yearly.0 $SNAPSHOT_RW/yearly.1;	\
fi;

# step 3: make a hard-link-only (except for dirs) copy of
# daily.1, assuming that exists, into yearly.0
# daily.1 is used since its the last backup of the previous month
if [ -d $SNAPSHOT_RW/daily.1 ] ; then			\
$CP -al $SNAPSHOT_RW/daily.1 $SNAPSHOT_RW/yearly.0 ;	\
fi;

# note: do *not* update the mtime of yearly.0; it will reflect
# when daily.1 was made, which should be correct.

# now remount the RW snapshot mountpoint as readonly

$MOUNT -o remount,ro $MOUNT_DEVICE $SNAPSHOT_RW ;
if (( $? )); then
{
	$ECHO "$($DATE) - snapshot: could not remount $SNAPSHOT_RW readonly" >> $DIAGNOSTICLOG;
	exit;
} fi;
$ECHO "$($DATE) - YEARLY ROTATION FINISHED" >> $DIAGNOSTICLOG;
