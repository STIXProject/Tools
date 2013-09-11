#!/usr/bin/env python

# Copyright (c) 2013, The MITRE Corporation. All rights reserved.
# See LICENSE.txt for complete terms.
'''
STIX Document Validator (sdv) - validates STIX v1.0 instance documents.
'''

import os
import argparse
from validator import XmlValidator 

def get_files_to_validate(dir):
    '''Return a list of xml files under a directory'''
    to_validate = []
    for top, dirs, files in os.walk(dir):
        for fn in files:
            if fn.endswith('.xml'):
                fp = os.path.join(top, fn)
                to_validate.append(fp)
    
    return to_validate

def error(msg):
    '''Print the error message and exit(1)'''
    print "[!] %s" % (msg)
    exit(1)

def main():
    parser = argparse.ArgumentParser(description="STIX Document Validator (sdv) - validated STIX v1.0 instance documents")
    parser.add_argument("--schema-dir", dest="schema_dir", default=None, help="Path to directory containing all necessary schemas for validation")
    parser.add_argument("--input-file", dest="infile", default=None, help="Path to STIX instance document to validate")
    parser.add_argument("--input-dir", dest="indir", default=None, help="Path to directory containing STIX instance documents to validate")
    parser.add_argument("--use-schemaloc", dest="use_schemaloc", action='store_true', default=False, help="Use schemaLocation attribute to determine schema locations.")
    
    args = parser.parse_args()
    
    if not(args.infile or args.indir):
        error("Must provide either --input-file or --input-dir argument")
    
    if args.infile and args.indir:
        error('Must provide either --input-file or --input-dir argument, but not both')
    
    if not(args.schema_dir or args.use_schemaloc):
        error("Must provide either --use-schemaloc or --schema-dir")
        
    if args.schema_dir and args.use_schemaloc:
        error("Most provide either --use-schemaloc or --schema-dir, but not both")
         
    if args.infile:
        to_validate = [args.infile]
    else:
        to_validate = get_files_to_validate(args.indir)
    
    if len(to_validate) > 0:
        print "[-] Processing %s files" % (len(to_validate))
        ssv = XmlValidator(schema_dir=args.schema_dir, use_schemaloc=args.use_schemaloc)
        for fp in to_validate:
            with open(fp, 'rb') as f:
                (result, msg) = ssv.validate(f)
                if result:
                    print "[+] %s : VALID" % (fp)
                else:
                    print "[!] %s : INVALID : %s" % (fp, msg)

if __name__ == '__main__':
    main()

    
