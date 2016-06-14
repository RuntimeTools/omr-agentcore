import json,sys

if len(sys.argv) < 2:
    print "Usage get_from_json file <field>"
    exit (-1)

with open(sys.argv[1]) as f:
    data = json.load(f)
    if len(sys.argv) > 2:
        key = sys.argv[2]
        if key in data:
            print ("%s"%data[key])
    else:
        for key in data:
            print ("%s=%s"%(key, data[key]))
