#!/usr/bin/env python3

import boto3
import concurrent.futures

class AWSRegions:
    profile = 'default'
    session = boto3.Session(profile_name=profile,region_name='us-east-1')
    regions = session.client('ec2')


    def __init__(self,*,state='running'):
        self.boto_client_object = self.regions
        self.state = state

    def get_regions(self):
        region_list = []
        region_data = self.boto_client_object.describe_regions()
        for region in region_data['Regions']:
            region_list.append(region['RegionName'])
        return tuple(region_list)

    def get_ec2s_in_region(self,region):
        dict_ec2 = {}
        session = boto3.Session(profile_name=self.profile,region_name=region)
        client = session.client('ec2')
        ec2 = client.describe_instances(Filters = [{'Name' : 'instance-state-name', 'Values': [self.state]}])
        dict_ec2[region] = len(ec2['Reservations'])
        print(dict_ec2)
        #return dict_ec2
        
if __name__ == "__main__":
    r = AWSRegions(state='running')
    tuple_regions = r.get_regions()
    #print(tuple_regions)
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(tuple_regions)) as executor:
       iter1=executor.map(r.get_ec2s_in_region, tuple_regions)
    #print(list(iter1))
