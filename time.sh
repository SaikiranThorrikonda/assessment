i=1
read -p "Enter the number of times you want to execute the curl request:" a

for i in $(eval echo {1..$a})
do
           curl -X POST https://2gh8ll9ay2.execute-api.us-east-2.amazonaws.com/datetime
           a=$((i+1))
           sleep 0.1
done
echo " "
echo " "
echo "====================================================="
echo  "  Curl POST Request sent --> " $i "times Successfully"
echo "====================================================="

