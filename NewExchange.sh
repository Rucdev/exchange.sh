#!/bin/bash
#Start
source Function_list
source MessageColor
menu="JPY KRW USD EUR"
##Base

printf "${BITBLIGHT}%s\033[m\n" "$msg_base" 
select item in $menu
do
case ${REPLY} in
	[1-9] | [1-2][0-9] | 3[0-2] )
		base_code=$(numTocode "${REPLY}")
	       break	;;
	[mM]ore )
		less ./countrytable 
		continue ;;
	[qQ] | [qQ]uit )
		echo "BYE (@|@)/~" 
		exit 0 ;;	

	* )
		printf "${RED}%s\033[m\n" "$msg_warn" ;;
esac
printf "${RED}You can only specify a number up to 32.\033[m\nIf you don't know the corresponding number, please enter \"more\"\n"
done
echo "You've set $base_code."

##Target
printf "${BITBLIGHT}%s\033[m\n" "$msg_target" 
select item in $menu
do
	
case ${REPLY} in
	[1-9] | [1-2][0-9] | 3[0-2] )
		target_code=$(numTocode "${REPLY}")
		if [ "$base_code" != "$target_code" ]; then
			break
		else
			printf "${RED}You're selecting the same one you selected earlier!\033[m\n"
		fi ;;
	[mM]ore )
		less ./countrytable 
		continue ;;
	[qQ] | [qQ]uit )
		echo "BYE (@|@)/~" 
		exit 0;;	
	* )
		printf "${RED}%s\033[m\n" "$msg_warn" ;;
esac
		printf "${RED}You can only specify a number up to 32.\033[m\nIf you don't know the corresponding number, please enter \"more\"\n"
done

echo "You've set $target_code."

#Get Exchange Rate
exchange_rate=$(GetRateFromTable "$base_code" "$target_code")

#Enter of Amount
while :
do
	printf "${BITBLIGHT}%s\033[m\n(%s)\n" "$msg_amounts" "$base_code"
	read kingaku
	isnum "$kingaku"
	if [ "$?" -eq 0 ]; then
	       	break
       	fi
	printf "${RED}%s\033[m\n" "$msg_warn" 
done

#Calculation
calc_result=$(RateCalc "$kingaku" "$exchange_rate")

#Output Result
OutputResult "$base_code" "$target_code" "$kingaku" "$exchange_rate" "$calc_result"
