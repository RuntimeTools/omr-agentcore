import sys, re
from optparse import OptionParser

usage = "usage: %prog [options] infile outfile"
parser = OptionParser(usage=usage)
parser.add_option("-f", "--from", dest="from_string", type="string",
                  help="The value to that will be replaced.")
parser.add_option("-t", "--to", dest="to_string", type="string",
                  help="The value used to replace the from string.")
parser.add_option("-v", "--verbose", action="store_true", default="false")

(options, args) = parser.parse_args()

if len(args) < 2:
    parser.print_usage()
    exit (-1)

infile = args[0]
outfile = args[1]

if options.verbose:
    print ("infile: %s" %infile)
    print ("outfile: %s" %outfile)
    if options.from_string != None and options.to_string != None:
        print ("Replacing '%s' with '%s'" % (options.from_string, options.to_string))
    elif options.to_string == None:
        print ("No replacement (missing --to argument)")
    elif options.from_string == None:
        print ("No replacement (missing --from argument)") 

with open(infile, 'r') as f:
    lines = f.readlines()
    with open(outfile, 'w') as o:
        for line in lines:
            if options.from_string != None and options.to_string != None:
                o.write(re.sub(options.from_string, options.to_string, line))
            else:
                o.write(line)
