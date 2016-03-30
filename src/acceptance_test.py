#!/usr/bin/env python
import os, sys

# run test file against scanner parser, and ast
# $python acceptance_test.py TESTFILE_PATH
if (len(sys.argv) >= 2):
    test_filepath = sys.argv[1]
    os.system("make clean")
    os.system("make debugtokens")

    os.system("./debugtokens.native < " + test_filepath + " > tokenized_test.txt")
    try:
        input_file = open("tokenized_test.txt", "r")
    except:
        print "File path incorrect!"
        sys.exit(2)
    string1 = ""
    for line in input_file:
        string1 += line
    string2 = string1.replace("\n", " ")
    output_file = open("formated_tokenized_test.txt", "w+")
    output_file.write(string2)
    output_file.write("\n")
    output_file.close()
    os.system("menhir --interpret --interpret-show-cst parser.mly < formated_tokenized_test.txt")
    try:
        x = sys.argv[2]
    except:
        os.system("rm formated_tokenized_test.txt tokenized_test.txt")
else:
    print "Usage: python acceptance_test.py test_filepath intermediate_files[optional]"
