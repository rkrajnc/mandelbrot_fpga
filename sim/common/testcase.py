#!/usr/bin/env python3

### testcase.py ###
### Testcase class ###
### 2020, rok.krajnc@gmail.com ###


"""Generic testcase class."""


### imports ###
import sys
import os
sys.path.append(os.path.dirname(os.path.realpath(__file__)))
from logger import Logger
from testcase_runner import TestcaseRunner
from testcase_runner_icarus import TestcaseRunnerIcarus
from testcase_runner_vivado import TestcaseRunnerVivado


### Testcase class ###
class Testcase:
  """Top class for testcases."""

  # defaults
  DEF_SIM_LST   = "sim.lst"
  DEF_LIB_LST   = "lib.lst"
  DEF_RTL_LST   = "rtl.lst"
  DEF_INC_LST   = "inc.lst"
  DEF_TESTNAME  = "test"
  DEF_OUT_DIR   = "out"
  DEF_BIN_DIR   = "bin"
  DEF_HEX_DIR   = "hex"
  DEF_WAV_DIR   = "wav"
  DEF_LOG_DIR   = "log"

  # init
  def __init__(self, working_dir : str, testcase_name=None, files_lists : dict = None, defines : dict = None, waves=False, expected_to_fail=False, logger : Logger = None, runner : str = None):
    # set working directory
    self.working_dir = working_dir
    # set testcase name
    self.testcase_name = self.DEF_TESTNAME if testcase_name is None else testcase_name
    # output directory
    self.out_dir = os.path.join("", *[self.working_dir, self.DEF_OUT_DIR])
    self.wrk_dir = os.path.join("", *[self.working_dir, self.DEF_OUT_DIR, self.testcase_name])
    # parse files
    self.parse_files_lists(files_lists)
    # test defines
    self.defines = {} if defines is None else defines
    # waves
    self.waves = waves
    # expected to fail
    self.expected_to_fail = expected_to_fail
    # logger
    self.logger = Logger() if logger is None else logger
    # runner
    if runner is None : runner = "icarus" # TODO
    if runner == "vivado":
      self.runner = TestcaseRunnerVivado(working_dir=self.wrk_dir, logger=self.logger, testcase_name=self.testcase_name)
    elif runner == "modelsim":
      pass # TODO
    elif runner == "icarus":
      self.runner = TestcaseRunnerIcarus(working_dir=self.working_dir, logger=self.logger, testcase_name=self.testcase_name)
    else:
      print("Unknown runner or runner not set, exiting.")
      sys.exit(-1)

  # log
  def log(self, message="", log_to_stdout=None):
    if self.logger:
      self.logger.log(message=message, log_to_stdout=log_to_stdout)
    elif log_to_stdout is not False:
      print(message)

  # set_logger
  def set_logger(self, logger : Logger):
    if self.logger:
      self.logger.close()
    self.logger = logger
    self.runner.logger = logger

  # parse_files_lists
  def parse_files_lists(self, files_lists : dict):
    from util import lst_parser
    self.files_lists = {}
    self.files_lists["inc"]  = os.path.join(self.working_dir, self.DEF_INC_LST) if files_lists is None else files_lists["inc"]
    self.files_lists["sim"]  = os.path.join(self.working_dir, self.DEF_SIM_LST) if files_lists is None else files_lists["sim"]
    self.files_lists["lib"]  = os.path.join(self.working_dir, self.DEF_LIB_LST) if files_lists is None else files_lists["lib"]
    self.files_lists["rtl"]  = os.path.join(self.working_dir, self.DEF_RTL_LST) if files_lists is None else files_lists["rtl"]
    self.files = {}
    self.files["inc"]       = lst_parser(self.files_lists["inc"])
    self.files["sim"]       = lst_parser(self.files_lists["sim"])
    self.files["lib"]       = lst_parser(self.files_lists["lib"])
    self.files["rtl"]       = lst_parser(self.files_lists["rtl"])

  # clean_wrk_dir()
  def clean_wrk_dir(self):
    from shutil import rmtree
    #self.logger.log("Clearing output directories ...")
    rmtree(self.wrk_dir, ignore_errors=True)

  # gen_run_dirs()
  def gen_run_dirs(self):
    from os.path import join
    from os import mkdir
    #self.log("Creating output directories ...")
    self.bin_dir = join(self.wrk_dir, self.DEF_BIN_DIR)
    self.hex_dir = join(self.wrk_dir, self.DEF_HEX_DIR)
    self.wav_dir = join(self.wrk_dir, self.DEF_WAV_DIR)
    self.log_dir = join(self.wrk_dir, self.DEF_LOG_DIR)
    self.dirs = {"out":self.out_dir, "wrk":self.wrk_dir, "bin":self.bin_dir, "hex":self.hex_dir, "wav":self.wav_dir, "log":self.log_dir}
    for item in [self.out_dir, self.wrk_dir, self.bin_dir, self.hex_dir, self.wav_dir, self.log_dir]:
      try:
        mkdir(item)
      except:
        pass

  # run
  def run(self, defines : dict = None):
    from os import chdir
    from os import getcwd
    # change cwd to working dir
    self.log("Changing CWD to: %s ..." % (self.working_dir))
    chdir(self.working_dir)
    # clean output directory
    #self.clean_wrk_dir() #TODO
    # create output directory
    self.gen_run_dirs()
    # open log
    if not self.logger.log_to_file:
      logname = os.path.join("", *[self.log_dir, self.testcase_name + ".log"])
      self.logger.open_file_log(filename=logname)
    else:
      self.logger.log()
      self.logger.log()
    self.logger.log_header()
    self.logger.log("CWD           : %s" % (getcwd()))
    self.logger.log("Testcase      : %s" % (self.testcase_name))
    self.logger.log("Testcase files:", log_to_stdout=False)
    from util import dict_to_str
    filesstr = dict_to_str(self.files).split("\n")
    for line in filesstr : self.logger.log("  " + line, log_to_stdout=False)
    # repository info
    from repository import Repository
    try:
      repo = Repository(self.working_dir)
      self.logger.log(self.logger.hr(), log_to_stdout=True)
      repo_info = repo.info()
      self.logger.log(repo_info, log_to_stdout=False)
      if "modified" in repo_info:
        self.logger.log("WARNING: repository NOT clean!")
      else:
        self.logger.log("INFO: repository IS clean.")
    except ValueError:
      self.logger.log("INFO: No GIT repository detected, skipping GIT checks.")
    #self.logger.log(self.logger.hr(), log_to_stdout=False)
    # run runner
    ret = self.runner.run(files = self.files, top=None, defines=self.defines, waves=self.waves, dirs=self.dirs)
    #self.logger.close() # TODO testcase should be able to close its logger by itself, not just from testset!
    self.logger.fd.flush()
    os.fsync(self.logger.fd.fileno())
    return ret
