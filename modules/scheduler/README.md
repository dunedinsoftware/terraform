
# AWS Instance scheduler
The scheduler manages the stopping and starting of simple EC2 instances that are not part of an Auto Scaling Group, based on cron-format schedules declared in the tags `schedule-start` and `schedule-stop`.

The scheduler polls every 5 minutes for any tag changes on EC2 instances within the VPC

## Module usage
Create a scheduler instance as follows:

```
module "scheduler" {
  source          = "https://github.com/dunedinsoftware/terraform/modules/scheduler"
  vpc_id          = <required>
  subnet_id       = <required>
  environment     = <optional, default: "default">
  instance_type   = <optional, default: "t2.micro">
}
```

## Example: Batch tagging a set of EC2 instances
Enumerate all EC2 instances tagged with a name starting "cbs", and schedule them to be up 8am - 7pm Mon-Fri, and down all weekend:

```
`aws ec2 describe-instances --filters Name=tag-value,Values=cbs* | jq '.Reservations[].Instances[] | [.InstanceId] | join(" ")' | sed -e 's/\"//g' | xargs -I {} aws ec2 create-tags --resources {} --tags 'Key=schedule-stop,Value=0 19 * * *' 'Key=schedule-start,Value=0 08 * * *'`
```

## Alternatives
You can use the [CloudFormation instance scheduler](https://aws.amazon.com/premiumsupport/knowledge-center/stop-start-instance-scheduler/)

Where your resources are managed by `Auto Scaling Groups`, you can schedule them [like this](https://aws.amazon.com/premiumsupport/knowledge-center/auto-scaling-use-scheduled-actions/). This would be the preferred way to schedule your resources, since ASG support EC2, FARGATE and ECS instances.
