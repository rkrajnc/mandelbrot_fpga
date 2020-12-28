#!/usr/bin/env python3

### testset.py ###
### Testset class ###
### 2020, rok.krajnc@gmail.com ###


"""Generic testset class."""


### imports ###
import sys, os
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), ".."))
from common.logger import Logger
from common.testcase import Testcase
from common.util import gen_testcase_variables_product
from common.util import gen_testcase_defines
from testcase_runner import TestcaseRunner
from testcase_runner_icarus import TestcaseRunnerIcarus
from testcase_runner_vivado import TestcaseRunnerVivado


### Testset class ###
class Testset:
  """Top class for testset, a collection of testcases."""

  def __init__(self, working_dir : str = None, testcases : list = [], runner : str = None, logger : Logger = None, testset_name=""):
    """Testset constructor."""
    self.working_dir = working_dir if working_dir is not None else ""
    self.testcases = testcases
    self.logger = Logger() if logger is None else logger
    self.testset_name = testset_name

  def append(self, testcase : Testcase):
    """Appends a testcase to the testset."""
    self.testcases.append(testcase)

  def run(self):
    """Run all testcases in testset."""
    logname = os.path.join("", *[self.working_dir, self.testset_name + ".log"])
    self.logger.open_file_log(filename=logname)
    self.results = []
    n_testcases = len(self.testcases)
    i = 1
    for testcase in self.testcases:
      testcase.set_logger(self.logger)
      print ("Running test %d / %d ..." % (i, n_testcases))
      i += 1
      if testcase.expected_to_fail:
        self.results.append(not testcase.run())
      else:
        self.results.append(testcase.run())
    self.log_results()
    if False in self.results:
      print("%d / %d testcase(s) FAILED" % (self.results.count(False), n_testcases))
    else:
      print("All %d testcase(s) PASSED" % (n_testcases))
    self.logger.close()
    return self.results

  def log_results(self, results=None):
    """Logs all testcases in testset and their pass / fail status."""
    results = results if results is not None else self.results
    testcase_max_length = len(max(self.testcases, key=lambda t : len(t.testcase_name)).testcase_name) # go over all testcase names, find (one of) the biggest and get the size of it
    result_fmt_str = "  %%-%ds : %%s" % (testcase_max_length)
    self.logger.log("Results:")
    for test_result in zip(self.testcases, self.results):
      self.logger.log(result_fmt_str % (test_result[0].testcase_name, "PASSED" if test_result[1] is True else "FAILED"))
