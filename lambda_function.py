#!/usr/bin/env python

import json
from botocore.vendored import requests # because it's a PITA to add dependancies
import os # To use the environmental variables instead of hard coding authentication.

def create_alert(filled, capacity, paid, due):
        output = "Filled: {} - Capacity: {} - Paid: {} - Due: {}".format(filled, capacity, paid, due)
        # Obtain this via https://ifttt.com/maker_webhooks (after login) then click on Documentation
        url = "https://maker.ifttt.com/trigger/and/with/key/yourkeyhere"
        r = requests.post(url, json={"value1" : str(filled), "value2" : str(paid), "value3" : str(due)})
        return output


def pase_res(data):
        state = "test"
        for i in data:
                # Name of the class to look for in the JSON blob
                if i["name"] == "Ability Driven Red Teaming: August 3-6":
                        state = create_alert(i['filled'], i['capacity'], i['paid'], i['due'])
        return state

def lambda_handler(event, context):
        result = "unknown"
        url = "http://location.for.json.blob/here.json"
        u = os.environ["USERNAME1"] #User environmental var
        p = os.environ["PASSWORD1"] #Pass environmental var

        try:
                result = requests.get(url, auth=(u,p))
                messages = result.json()
                res = pase_res(messages)
                print(res)
                return {
                        'statusCode': 200,
                        'body': json.dumps(res)
                }
        except IOError as e:
                print (e)
                return {
                        'statusCode': 404,
                        'body': json.dumps(str(e))
                }
