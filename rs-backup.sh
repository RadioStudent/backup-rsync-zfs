#!/bin/bash
#
# Do rsync backups to local ZFS storage (with snapshots)
# 
# This and all related files in this directory are in the public domain.
#
# Author: Borut Mrak
#
# Requires:
#   * rsync
#   * ZFS
#   * zfs-auto-snapshot
#   * zip (to compress logs for mail reports)
#   * mutt (to send mail with attachment)
#
MAIL_RECIPS=""

MYDIR=`dirname $0`
cd $MYDIR

TIMESTAMP=`date +%Y%m%d-%H%M%S`

LOGDIR=/var/log/rs-backups
if [ ! -d ${LOGDIR} -o ! -d ${LOGDIR}/jobs ]; then
  echo "${LOGDIR}/jobs does not exist. Create it first."
  exit 1
fi

ERRORS=0
for job in `ls jobs/*.conf`; do
  ${MYDIR}/run_job $job | tee -a ${LOGDIR}/${job}-${TIMESTAMP}.log
  rv=$?
  if [ $rv -gt 0 ]; then
    ERRORS=1
  fi
done

#
# send mail
#
if [ $ERRORS -gt 0 ]; then
  mail_subject="RS-BACKUP: ERRORS (${TIMESTAMP})"
else
  mail_subject="RS-BACKUP: OK (${TIMESTAMP})"
fi

# create zip attachment with the logs
zip -j ${LOGDIR}/${TIMESTAMP}-logs.zip ${LOGDIR}/jobs/*-${TIMESTAMP}.log && \
  rm -f ${LOGDIR}/jobs/*-{TIMESTAMP}.log

if [ ! -z $MAIL_RECIPS ]; then
  mutt -s "$mail_subject" "$MAIL_RECIPS" -a ${LOGDIR}/*-${TIMESTAMP}-logs.zip <<< "logs attached"
fi
  
