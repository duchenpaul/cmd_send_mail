#!/bin/bash
SOURCE=`basename $0 .sh`

LOG_PATH=./script_logs
LOG=${LOG_PATH}/${SOURCE}_`date +"%Y%m%d"`.log
SEND_MAIL_SCRIPT=./send_mail.py

usage(){
	echo "Sending notification with the result of command."
	echo "$0 <CMD>"
}


send_mail(){
	check_count=1
	while [ ${check_count} -le 3 ]; do
		sudo timeout 20m python3 ${SEND_MAIL_SCRIPT} "${subject}" "${content}" 
		rtncode=$?
		echo "send mail return code: ${rtncode},tried $check_count time(s)"

		if [ ${rtncode} -eq 0 ]; then
			break
		fi
		check_count=$(($check_count + 1))
	done
}

exit_process(){
	exit_code=$1
	case $exit_code in
		0 )		
			subject="[Success] Script has completed at `date '+%b %d %T'`"
			content="Script ${cmd} has completed at `date`, elapsed $(($duration / 60)) minutes and $(($duration % 60)) seconds "
			send_mail
			;;
		1 )
			subject="[Fail] Script has failed at `date '+%b %d %T'`"
			content="Script ${cmd} has failed at `date`, elapsed $(($duration / 60)) minutes and $(($duration % 60)) seconds "
			send_mail
			;;

		* )
			echo "Undefined Return Code!"
			;;
	esac
	echo ${content}
	echo -e "$0 ended at `date`\n\n" 
	exit $exit_code

}

check_result()
{
	duration=$SECONDS
	return_status=$?
	if [ $return_status -ne 0 ]; then
		echo -e "`date '+%F %X'`: Failed! Return Status = $return_status"
		exit_process 1
	else
		echo -e "`date '+%F %X'`: Done!"
	fi
}


if [ $# -ne 1 ]; then
	usage
	exit 1
fi

cmd=$1

mkdir ${LOG_PATH}
# echo "" > ${LOG}
exec >> ${LOG} 2>&1
echo "$0 started at `date '+%b %d %T'` \n"
echo "`date '+%F %X'`: Executing ${cmd}... \n"
SECONDS=0
${cmd}
check_result
exit_process 0
