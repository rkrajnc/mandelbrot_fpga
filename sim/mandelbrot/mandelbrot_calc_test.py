#!/usr/bin/env python3

import sys, os
import copy
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), ".."))
from common.testset import Testset
from common.testcase import Testcase
from common.util import gen_testcase_variables_product
from common.util import gen_testcase_defines


SCRIPT_PATH = os.path.dirname(os.path.realpath(__file__))


### testset_gen() ###
def testset_gen(waves=False):
  test_name = "mandelbrot_calc"
  testset = Testset(testset_name=test_name)
  expect_to_fail = False
  testcase_name = "%s" % (test_name)
  define = []
  testset.append(Testcase(working_dir=SCRIPT_PATH, testcase_name=testcase_name, defines=define, waves=waves, expected_to_fail=expect_to_fail))
  return testset


### module options ###
waves               = True


### generate and run testcases ###
os.chdir(SCRIPT_PATH)
testset = testset_gen(waves=waves)
results = testset.run()

