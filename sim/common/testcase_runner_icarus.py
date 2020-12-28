#!/usr/bin/env python3

### testcase_runner_icarus.py ###
### class for Icarus Verilog testcase runner ###
### 2020, rok.krajnc@gmail.com ###


"""Class for Icarus Verilog testcase runner."""


from testcase_runner import TestcaseRunner
from logger import Logger


class TestcaseRunnerIcarus(TestcaseRunner):
  """Class for Icarus Verilog testcase runner."""

  compiler_name   = "iverilog"
  compiler_params = ["g2012", "Wall", "Winfloop", "Wno-timescale"]
  runner_name     = "vvp"
  runner_params   = ["lxt2"]#["fst"]

  # init()
  def __init__(self, working_dir : str, out_dir : str = None, logger : Logger = None, testcase_name = "test"):
    super().__init__(working_dir=working_dir, out_dir=out_dir, logger=logger, testcase_name=testcase_name)

  # gen_compiler_cmd()
  def gen_compiler_cmd(self, files : dict, dirs: dict, top : str = None, defines : dict = None, testcase_name=None, waves=False):
    from os.path import join
    from os.path import relpath
    testcase_name = self.testcase_name if testcase_name is None else testcase_name
    compiler_cmd_str = ""
    # program
    compiler_cmd_str += self.compiler_name
    # program params
    params_str = ""
    for param in self.compiler_params : params_str += " -%s" % (param)
    compiler_cmd_str += params_str
    # defines
    defines_str = ""
    defines_str += " -DSIM_ICARUS"
    if waves:
      defines_str += " -DSIM_WAVES"
      wavefile_path = join("", *[dirs["wav"], "waves.vcd"])
      wavefile_path_rel = relpath(path=wavefile_path, start=self.working_dir).replace("\\", "/")
      print(wavefile_path_rel)
      defines_str += " -DWAV_FILE=\\\"%s\\\"" % (wavefile_path_rel)
    if defines is not None:
      for define in defines:
        if (defines[define] is None) or (defines[define] == ""):
          defines_str += " -D%s" % (define)
        else:
          defines_str += " -D%s=%s" % (define, defines[define])
    compiler_cmd_str += defines_str
    # include dirs
    includes_str = ""
    for directory in files["inc"] : includes_str += " -I%s" % (directory)
    compiler_cmd_str += includes_str
    # top
    if top is not None : compiler_cmd_str += " -s %s" % (top)
    # output file name
    output_fn = join("", *[dirs["bin"], testcase_name])
    compiler_cmd_str += " -o \"%s\"" % (output_fn)
    # files
    sim_files_list = []
    sim_files_list.extend(files["sim"])
    sim_files_list.extend(files["lib"])
    sim_files_list.extend(files["rtl"])
    sim_files_str = " " + " ".join(sim_files_list)
    compiler_cmd_str += sim_files_str
    # done
    return compiler_cmd_str

  # gen_runner_cmd
  def gen_runner_cmd(self, dirs : dict, testcase_name=None):
    from os.path import join
    testcase_name = self.testcase_name if testcase_name is None else testcase_name
    runner_cmd_str = ""
    # program
    runner_cmd_str += self.runner_name
    # script
    script_fn = join("", *[dirs["bin"], testcase_name])
    runner_cmd_str += " \"%s\"" % (script_fn)
    # program params
    params_str = ""
    for param in self.runner_params : params_str += " -%s" % (param)
    runner_cmd_str += params_str
    return runner_cmd_str

  # run
  def run(self, files : dict, dirs : dict, top : str = None, defines : dict = None, waves : bool = False):
    import subprocess
    from shlex import split
    # generate compiler cmd
    compiler_cmd = self.gen_compiler_cmd(files=files, dirs=dirs, defines=defines, waves=waves)
    # compile
    self.log(self.logger.hr())
    self.log("Running compiler: \"%s\" ..." % (compiler_cmd))
    compile_result = subprocess.run(split(compiler_cmd), stdout=subprocess.PIPE, stderr=subprocess.STDOUT) # using shlex.split, as posix shells can be pedantic
    compile_text = compile_result.stdout.decode("utf-8").splitlines()
    ret = True
    for line in compile_text:
      if ("Error" in line) or ("error" in line) or ("ERR" in line):
        self.log("ERROR: %s" % (line))
        ret = False
      elif ("Warning" in line) or ("warning" in line) or ("WARN" in line) or ("WRN" in line):
        self.log("WARNING: %s" % (line))
      else:
        self.log(line, log_to_stdout=False)
    if (compile_result.returncode != 0) or (ret is False):
      self.log("ERROR: Error in compilation step, exiting.")
      return False
    # generate runner cmd
    runner_cmd = self.gen_runner_cmd(dirs=dirs)
    # run
    self.log(self.logger.hr())
    self.log("Running simulation: \"%s\" ..." % (runner_cmd))
    run_result = subprocess.run(split(runner_cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    run_text = run_result.stdout.decode("utf-8").splitlines()
    # parse output
    for line in run_text:
      if line.startswith("ERR"):
        self.log("ERROR: %s" % (line))
      elif line.startswith("WARN"):
        self.log("WARNING: %s" % (line))
      if line.startswith("FATAL"):
        self.log("ERROR: testbench failed (%s)" % (line))
        ret = False
      elif "FAIL" in line:
        self.log("ERROR: testbench failed (%s)" % (line))
        ret = False
      elif (ret == False) and ("PASS" in line):
        self.log("INFO: testbench passed (%s)" % (line))
        ret = True
      else:
        self.log(line, log_to_stdout=False)
    if run_result.returncode != 0:
      self.log("ERROR: Error in run step.")
      ret = False
    if ret is None:
      ret = False
      self.log("ERROR: no PASS/FAIL in simulation output, considering it a FAIL.")
    self.log(self.logger.hr())
    return ret
