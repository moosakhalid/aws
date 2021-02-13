## Dumping rough notes here, will clean up later
### Assuming this is all done on an EC2

1. Need an IAM role with the following IAM policy: **CloudWatchAgentServerPolicy** , this is a AWS managed policy.

   Note: I would also recommend adding the policy **AmazonEC2RoleforSSM** to the same role so you can log in using SSM Session Manager
         and skip generating key pairs.
         
2. Assuming you're setting up on an Amazon Linux 2 or even if you're not follow this [link](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/download-cloudwatch-agent-commandline.html)
   
   If using Amazon Linux 2, its as easy as a `sudo yum -y install amazon-cloudwatch-agent`, so why go through the hassle of anything else! :p


3. I used `collectd` to pass custom metrics to CW on top of the base ones that it populates. To set it up one needs to modify the 
   Amazon CW agent config file, which is housed under `/opt/aws/amazon-cloudwatch-agent/etc/` . It's a JSON file, can be given any arbitrary name
   and should end in `.json` extension. Use this page to get hints on how to build the sample file.

   a. To install collectd:
     ```
   sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
   sudo yum install -y collectd
     ```
     
   b. Start `collectd`: 
      `sudo systemctl start collectd` [docs-link-here](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-custom-metrics-collectd.html)
  

4. Sample AWS CloudWatch Agent config file is in this same repo name: `amazon-cloudwatch-agent.json`, you can also generate it using this doc
   where you're taken through the CW agent wizard:
   [docs-link-here](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-cloudwatch-agent-configuration-file-wizard.html)
   
   Basically there's 2 sections in our scenario: **agent** section and a **metrics** section.
   *Agent** section defines config for which region agent will send logs to, any role that it needs to send logs/metrics to another account and 
   what custom tool to use to get custom metrics, for example you can use StatsD, collectd or ethtool.
   **Metrics* section is where you can define what pre-populated custom metric

5. Restart/Start CW agent:
   ```
   sudo systemctl start amazon-cloudwatch-agent
   ```
   ------
Now give it a few minutes and then go look at CW Metrics console, by default , unless you provide a namespace its going to log all metrics from the EC2
under `CWAgent`


Hint:
1. You can enable `debug` to `true` inside the `agent` section of your CW agent config to see all details under the default CW agent logging file at:
   ```
   /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
   ```
   
   
Improvement that can be made:
1. Put custom metrics under set dimensions, something the above method doesn't do.
2. Modify units of metrics to your liking.
