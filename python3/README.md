# Parallel task execution using concurrent.futures Python module

Need: To be able to quickly scout all AWS regions for a resource, in this case RUNNING EC2 instances.
      By default AWS CLI blocks call between checking in each region if used in a loop, however using
      AWS Boto3 Sessions and concurrent.futures ThreadPool execution we can issue as many simultaneous
      API calls as the regions and get back results within 2 to 3 seconds instead of 3 or 4 minutes.
      
Note: Assumes that AWS credentials are either setup in .aws credentials directory or assumed via a role
