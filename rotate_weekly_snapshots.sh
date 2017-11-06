#!/bin/bash
# ----------------------------------------------------------------------
# mikes handy rotating-filesystem-snapshot utility: weekly snapshots
# ----------------------------------------------------------------------
# intended to be run weekly as a cron job when daily.6 contains the
# Sunday (or whenever you want) snapshot; say, Monday morning.
# ----------------------------------------------------------------------


export DIRNAME=/usr/bin/dirname;
export REALPATH=/usr/bin/realpath;

unset PATH

CWD=`$DIRNAME $($REALPATH $0)`
source $CWD/backup.config;

# ------------- the script itself --------------------------------------
$TOUCH $DIAGNOSTICLOG;
$ECHO "*****************************************************************************" >> $DIAGNOSTICLOG;
$ECHO "$($DATE) - WEEKLY ROTATION STARTED" >> $DIAGNOSTICLOG;
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
if [ -d $SNAPSHOT_RW/weekly.4 ] ; then
$RM -rf $SNAPSHOT_RW/weekly.4 ;
fi ;

# step 2: shift the middle snapshots(s) back by one, if they exist
if [ -d $SNAPSHOT_RW/weekly.3 ] ; then
  $MV $SNAPSHOT_RW/weekly.3 $SNAPSHOT_RW/weekly.4 ;
fi;
if [ -d $SNAPSHOT_RW/weekly.2 ] ; then
  $MV $SNAPSHOT_RW/weekly.2 $SNAPSHOT_RW/weekly.3 ;
fi;
if [ -d $SNAPSHOT_RW/weekly.1 ] ; then
  $MV $SNAPSHOT_RW/weekly.1 $SNAPSHOT_RW/weekly.2 ;
fi;
if [ -d $SNAPSHOT_RW/weekly.0 ] ; then
  $MV $SNAPSHOT_RW/weekly.0 $SNAPSHOT_RW/weekly.1;
fi;

# step 3: make a hard-link-only (except for dirs) copy of
# daily.1, assuming that exists, into weekly.0
if [ -d $SNAPSHOT_RW/daily.1 ] ; then
  $CP -al $SNAPSHOT_RW/daily.1 $SNAPSHOT_RW/weekly.0 ;
fi;

# note: do *not* update the mtime of weekly.0; it will reflect
# when daily.1 was made, which should be correct.

# now remount the RW snapshot mountpoint as readonly

$MOUNT -o remount,ro $MOUNT_DEVICE $SNAPSHOT_RW ;
if (( $? )); then
{
  $ECHO "$($DATE) - snapshot: could not remount $SNAPSHOT_RW readonly" >> $DIAGNOSTICLOG;
  exit;
}
fi;
$ECHO "$($DATE) - WEEKLY ROTATION FINISHED" >> $DIAGNOSTICLOG;

