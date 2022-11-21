rm -f crontab.tmp
echo "PATH=/bin:/usr/bin:/usr/local/bin" > crontab.tmp
echo "*/5 * * * * ./scheduler.sh" >> crontab.tmp
aws ec2 describe-instances --filters Name=tag-key,Values=schedule-start Name=instance-state-name,Values=running,stopped | jq '.Reservations[].Instances[] | [(.Tags[]|select(.Key=="schedule-start")|.Value), "aws ec2 start-instances --instance-ids", .InstanceId] | join(" ")' | sed -e 's/\"//g' >> crontab.tmp
aws ec2 describe-instances --filters Name=tag-key,Values=schedule-stop Name=instance-state-name,Values=running,stopped | jq '.Reservations[].Instances[] | [(.Tags[]|select(.Key=="schedule-stop")|.Value), "aws ec2 stop-instances --instance-ids", .InstanceId] | join(" ")' | sed -e 's/\"//g' >> crontab.tmp
crontab crontab.tmp && rm -f crontab.tmp
