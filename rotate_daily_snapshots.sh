#!/bin/bash
# ----------------------------------------------------------------------
# mikes handy rotating-filesystem-snapshot utility: daily snapshots
# ----------------------------------------------------------------------
# intended to be run daily as a cron job when hourly.3 contains the
# midnight (or whenever you want) snapshot; say, 13:00 for 4-hour snapshots.
# ----------------------------------------------------------------------

unset PATH

CWD=`dirname $(realpath $0)`
source $CWD/backup.config;

# ------------- the script itself --------------------------------------
$TOUCH $DIAGNOSTICLOG;
$ECHO "$($DATE) - DAILY ROTATION STARTED" >> $DIAGNOSTICLOG;
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
if [ -d $SNAPSHOT_RW/daily.6 ] ; then			\
$RM -rf $SNAPSHOT_RW/daily.6 ;				\
fi ;

# step 2: shift the middle snapshots(s) back by one, if they exist
if [ -d $SNAPSHOT_RW/daily.5 ] ; then			\
$MV $SNAPSHOT_RW/daily.5 $SNAPSHOT_RW/daily.6 ;	\
fi;
if [ -d $SNAPSHOT_RW/daily.4 ] ; then			\
$MV $SNAPSHOT_RW/daily.4 $SNAPSHOT_RW/daily.5 ;	\
fi;
if [ -d $SNAPSHOT_RW/daily.3 ] ; then			\
$MV $SNAPSHOT_RW/daily.3 $SNAPSHOT_RW/daily.4 ;	\
fi;
if [ -d $SNAPSHOT_RW/daily.2 ] ; then			\
$MV $SNAPSHOT_RW/daily.2 $SNAPSHOT_RW/daily.3 ;	\
fi;
if [ -d $SNAPSHOT_RW/daily.1 ] ; then			\
$MV $SNAPSHOT_RW/daily.1 $SNAPSHOT_RW/daily.2 ;	\
fi;
if [ -d $SNAPSHOT_RW/daily.0 ] ; then			\
$MV $SNAPSHOT_RW/daily.0 $SNAPSHOT_RW/daily.1;	\
fi;

# step 3: make a hard-link-only (except for dirs) copy of
# hourly.3, assuming that exists, into daily.0
if [ -d $SNAPSHOT_RW/hourly.3 ] ; then			\
$CP -al $SNAPSHOT_RW/hourly.3 $SNAPSHOT_RW/daily.0 ;	\
fi;

# note: do *not* update the mtime of daily.0; it will reflect
# when hourly.3 was made, which should be correct.

# now remount the RW snapshot mountpoint as readonly

$MOUNT -o remount,ro $MOUNT_DEVICE $SNAPSHOT_RW ;
if (( $? )); then
{
	$ECHO "$($DATE) - snapshot: could not remount $SNAPSHOT_RW readonly" >> $DIAGNOSTICLOG;
	exit;
} fi;
$ECHO "$($DATE) - DAILY ROTATION FINISHED" >> $DIAGNOSTICLOG;
