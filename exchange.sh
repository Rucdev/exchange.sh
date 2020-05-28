#!/bin/bash
#Start 
source function_module
source error_trap

#Choice base currency
head countrytable
while :
do
	msgPattern
	read input_curr
	if [ "$input_curr" = 'M' ];then
		less countrytable
	elif [ "$input_curr" -ge 1 | "$input_curr" -le 32 ]; then

#Convert the entered value to a currency code
		base_code=$(numTocode "$input_curr")
		break
	else
		searchCCT $input_curr
	fi
done

#Target
while :
do
	msgPattern $base_code
	read input_curr
	if [ "$input_curr" = 'M' ];then
		less countrytable
	elif [ "$input_curr" -ge 1 | "$input_curr" -le 32 ]; then

#Convert the entered value to a currency code
		target_code=$(numTocode "$input_curr")
		if [ "$base_code" = "$target_code" ]; then
			warningMSG	
		else
			break
		fi
	else
		searchCCT $input_curr
	fi

#Enter the amount of your currency
echo "How mach do you want to exchange?($base_code)"
read amount

#Check amount

#Get the desired rate in one shot
target_rate=$(rafrta "$base_code" "$target_code") 

#Calculate
result=$(echo "scale=12; ($target_rate * $amount)" | bc)

#Output result
echo "$result ($target_code)"

