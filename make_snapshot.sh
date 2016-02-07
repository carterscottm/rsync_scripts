#!/bin/bash
# ----------------------------------------------------------------------
# mikes handy rotating-filesystem-snapshot utility
# ----------------------------------------------------------------------
# this needs to be a lot more general, but the basic idea is it makes
# rotating backup-snapshots of /home whenever called
# ----------------------------------------------------------------------

unset PATH	# suggestion from H. Milz: avoid accidental use of $PATH

# ------------- system commands used by this script --------------------
ID=/usr/bin/id;
ECHO=/bin/echo;
MOUNT=/bin/mount;
RM=/bin/rm;
MV=/bin/mv;
CP=/bin/cp;
TOUCH=/bin/touch;
DATE=/bin/date;
SUSPEND=/usr/sbin/pm-suspend;
RSYNC=/usr/bin/rsync;
TAIL=/usr/bin/tail;
SED=/bin/sed;
# ------------- file locations -----------------------------------------

MOUNT_DEVICE=nas1:nfs/linuxbackup;
SNAPSHOT_RW=/root/snapshot;
EXCLUDES=/opt/scripts/backup/backup_exclude;
INCLUDES=/opt/scripts/backup/backup_include;

# ------------- set date and time for backup log -----------------------

DATESTAMP=$($DATE +%Y%m%d%H%M);
LOGFILE=rsync.log.$($DATE +%Y%m%d%H%M%S);
DIAGNOSTICLOG=/home/scott/backupdiag.log;
# ------------- the script itself --------------------------------------
$TOUCH $DIAGNOSTICLOG;
$ECHO "*****************************************************************************" >> $DIAGNOSTICLOG;
$ECHO "$($DATE) - SNAPSHOT CREATION STARTED" >> $DIAGNOSTICLOG;

# make sure we're running as root
if [ `$ID -u` != "0" ]; then { $ECHO "$($DATE) - This script must be run as root" >> $DIAGNOSTICLOG; exit 1; } fi

# attempt to remount the RW mount point as RW; else abort
$MOUNT -o remount,rw $MOUNT_DEVICE $SNAPSHOT_RW ;
if (( $? )); then
{
	$ECHO "$($DATE) - SNAPSHOT: could not remount $SNAPSHOT_RW readwrite" >> $DIAGNOSTICLOG;
	exit;
}
fi;


# rotating snapshots

# step 1: delete the oldest snapshot, if it exists:
if [ -d $SNAPSHOT_RW/daily.6 ] ; then                   \
	$RM -rf $SNAPSHOT_RW/daily.6 ;                          \
fi ;

# step 2: shift the middle snapshots(s) back by one, if they exist
if [ -d $SNAPSHOT_RW/daily.5 ] ; then                   \
	$MV $SNAPSHOT_RW/daily.5 $SNAPSHOT_RW/daily.6 ; \
fi;
if [ -d $SNAPSHOT_RW/daily.4 ] ; then                   \
	$MV $SNAPSHOT_RW/daily.4 $SNAPSHOT_RW/daily.5 ; \
fi;
if [ -d $SNAPSHOT_RW/daily.3 ] ; then                   \
	$MV $SNAPSHOT_RW/daily.3 $SNAPSHOT_RW/daily.4 ; \
fi;
if [ -d $SNAPSHOT_RW/daily.2 ] ; then                   \
	$MV $SNAPSHOT_RW/daily.2 $SNAPSHOT_RW/daily.3 ; \
fi;
if [ -d $SNAPSHOT_RW/daily.1 ] ; then                   \
	$MV $SNAPSHOT_RW/daily.1 $SNAPSHOT_RW/daily.2 ; \
fi;
# step 3: make a hard-link-only (except for dirs) copy of the latest snapshot,
# if that exists
if [ -d $SNAPSHOT_RW/daily.0 ] ; then			\
$CP -al $SNAPSHOT_RW/daily.0 $SNAPSHOT_RW/daily.1 ;	\
fi;

# step 4: rsync from the system into the latest snapshot (notice that
# rsync behaves like cp --remove-destination by default, so the destination
# is unlinked first.  If it were not so, this would copy over the other
# snapshot(s) too!
$RM -f /Installed_Packages
/usr/bin/dpkg --get-selections > /Installed_Packages
$RSYNC								\
	-vha --delete --delete-excluded				\
	--exclude-from="$EXCLUDES" --include-from="$INCLUDES"	\
	/ $SNAPSHOT_RW/daily.0 --log-file=$SNAPSHOT_RW/$LOGFILE;

$MV $SNAPSHOT_RW/$LOGFILE $SNAPSHOT_RW/daily.0/

# step 5: update the mtime of daily.0 to reflect the snapshot time
$TOUCH $SNAPSHOT_RW/daily.0 -t $DATESTAMP;

# and thats it for home.

# now remount the RW snapshot mountpoint as readonly

$MOUNT -o remount,ro $MOUNT_DEVICE $SNAPSHOT_RW ;
if (( $? )); then
{
	$ECHO "$($DATE) - SNAPSHOT: could not remount $SNAPSHOT_RW readonly" >> $DIAGNOSTICLOG;
	exit;
} fi;
$TAIL $SNAPSHOT_RW/daily.0/$LOGFILE -n 2 | $SED -e 's/.*\]//' >> $DIAGNOSTICLOG;
$ECHO "$($DATE) - SNAPSHOT CREATION FINISHED, GOING BACK TO SLEEP" >> $DIAGNOSTICLOG;
$SUSPEND;