#!/usr/bin/env python3

### util.py ###
### utility functions for simulations ###
### 2020, rok.krajnc@gmail.com ###


"""Common utility functions for simulations."""


### lst_parser() ###
def lst_parser(lst_file : str = None):
  """Parses .lst files and returns a list of filenames."""
  import os
  if not os.path.isfile(lst_file) : raise FileNotFoundError("Can't open file \"%s\"." % lst_file)
  file_list = [line.strip() for line in open(lst_file) if line.strip() != "" and line.strip()[0] != "#"] # relies on short-circuit evaluation
  #print (file_list)
  return file_list


### split_by_extension() ###
def split_by_extension(file_list : list = None):
  """Splits a filelist according to file extension and returns a dict with all files grouped into extensions."""
  import os
  if file_list is None : raise ValueError("Empty file list.")
  split_list = {}
  for file in file_list:
    ext = os.path.splitext(file)[1][1:]
    if ext not in split_list:
      split_list[ext] = []
    split_list[ext].append(file)
  #print (split_list)
  return split_list


### is_posix() ###
def is_posix():
  """Returns True if script is running on Posix-like OS (Linux, Cygwin, ...)."""
  import os
  #print(os.name) # "nt" on Windows, "posix" on Cygwin, Linux
  #import platform
  #print(platform.system()) # "windows" on Windows, "CYGWIN_NT-10.0-WOW" on Cygwin
  #import sys
  #print(sys.platform) # "win32" on Windows, "cygwin" on Cygwin
  return os.name == "posix"


### dict_to_str() ###
def dict_to_str(var : dict):
  """Formats dictionary for nice string output."""
  ret = ""
  for item in var:
    if type(var[item]) is list:
      ret += "%s:\n" % (item)
      for listitem in var[item]:
        ret += "  %s\n" % (listitem)
    else:
      ret += "%s\n" % (item)
  return ret


### gen_testcase_variables_product() ###
def gen_testcase_variables_product(testcase_variables: dict):
  """Returns a list of variables and a crossproduct of all variables options."""
  from itertools import product
  variables_product = product(*[list(item.values())[0] for item in testcase_variables])
  variables_list = [list(item.keys())[0] for item in testcase_variables]
  return variables_list, variables_product


### gen_testcase_defines() ###
def gen_testcase_defines(variables_list, variables_product):
  """Returns a list of defines generated from a variables list and a variables crossproduct."""
  defines = []
  for product in variables_product:
    define = {}
    for i in range(len(variables_list)):
      define[variables_list[i]] = product[i]
    defines.append(define)
  return defines
