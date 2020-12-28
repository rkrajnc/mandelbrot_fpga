#!/usr/bin/env python3


### logger.py ###
### class for Logging messages to stdout / file ###
### 2020, rok.krajnc@gmail.com ###


"""Class for logging."""


class Logger:
  
  def __init__(self, log_to_stdout=True, log_to_file=False, file_append=False, filename="test.log"):
    self.log_to_stdout = log_to_stdout
    self.log_to_file = log_to_file
    self.filename = filename
    open_mode = "w" if file_append is False else "w+"
    self.fd = open(self.filename, open_mode) if log_to_file is True else None

  def open_file_log(self, file_append=False, filename="test.log"):
    open_mode = "w" if file_append is False else "w+"
    self.filename = filename
    self.fd = open(self.filename, open_mode)
    self.log_to_file = True

  def filelog(self, message):
    if self.fd : self.fd.write(message + "\n")
  
  def stdoutlog(self, message):
    print(message)
  
  def log(self, message="", log_to_stdout=None, log_to_file=None):
    if log_to_stdout is None:
      if self.log_to_stdout : self.stdoutlog(message)
    else:
      if log_to_stdout : self.stdoutlog(message)
    if log_to_file is None:
      if self.log_to_file : self.filelog(message)
    else:
      if log_to_file : self.filelog(message)
  
  def hr(self, linefeed = False):
    ret = "****************************************************************************************************************************************************************"
    if linefeed : ret += "\n"
    return ret

  def log_header(self, log_to_stdout=None, log_to_file=None):
    import datetime
    from getpass import getuser
    from socket import gethostname
    msg =  self.hr(linefeed=True)
    now = datetime.datetime.now()
    now_str = now.strftime("%Y-%m-%d %H:%M:%S")
    msg += "Log started on: %s\n" % (now_str)
    msg += "User          : %s\n" % (getuser())
    msg += "Computer      : %s\n" % (gethostname())
    msg += self.hr()
    self.log(msg)

  def close(self):
    if self.fd : self.fd.close()

  def __del__(self):
    self.close()
