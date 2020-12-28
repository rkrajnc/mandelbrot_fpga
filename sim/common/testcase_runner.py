#!/usr/bin/env python3

### testcase_runner.py ###
### parent class for all testcase runners ###
### 2020, rok.krajnc@gmail.com ###


"""Parent class for all testcase runners."""


### imports ###
from logger import Logger


class TestcaseRunner:

  out_dir_name    = "out"

  # init()
  def __init__(self, working_dir : str, out_dir : str = None, logger : Logger = None, testcase_name = "test"):
    from os.path import join
    self.logger = logger
    self.working_dir = working_dir
    self.out_dir  = join(self.working_dir, self.out_dir_name) if out_dir is None else out_dir
    self.testcase_name = testcase_name

  def run(self) : pass

  # log()
  def log(self, message : str = "", log_to_stdout : bool = None):
    if self.logger:
      self.logger.log(message=message, log_to_stdout=log_to_stdout)
    elif log_to_stdout is not False:
      print(message)

