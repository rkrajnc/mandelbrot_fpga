#!/usr/bin/env python3

### repository.py ###
### Repository class ###
### 2020, rok.krajnc@gmail.com ###


### imports ###
import git
import sys


### Repository class ###
class Repository:
  """Repository class, providing various information about the state of the repository."""

  repo = None

  def __init__(self, working_dir=None):
    """Repository class constructor."""
    if working_dir is not None : self.set_working_dir(working_dir)

  def set_working_dir(self, working_dir):
    """Sets working directory."""
    self.working_dir = working_dir
    try:
      self.repo = git.Repo(working_dir, search_parent_directories=True)
    except Exception as e:
      raise ValueError("Couldn't get repository in %s (%s), exiting." % (self.working_dir, e))

  def get_status(self):
    """Returns status of GIT repository located in path, or None if no repo exist at the location."""
    status = None
    try:
      status = self.repo.git.status()
    except:
      pass
    return status

  def get_last_tag(self):
    """Returns last tag of repository, or None if no tag is found."""
    last_tag = None
    try:
      tags = sorted(self.repo.tags, key = lambda t : t.commit.committed_datetime)
      last_tag = tags[-1]
    except:
      pass
    return last_tag

  def get_current_branch(self):
    """Returns current branch of repository."""
    branch = None
    try:
      branch = self.repo.active_branch
    except:
      pass
    return branch

  def get_last_commit_sha(self):
    """Returns last commit id of repository, or None if no commit is found."""
    last_commit = None
    try:
      last_commit = self.repo.head.object.hexsha
    except:
      pass
    return last_commit

  def info(self):
    """Returns a string with current repository information."""
    ret = "Repository info:\n"
    ret += "  branch      : %s\n" % (self.get_current_branch())
    ret += "  last tag    : %s\n" % (self.get_last_tag())
    ret += "  last commit : %s\n" % (self.get_last_commit_sha())
    ret += "  status:\n"
    lines = self.get_status().splitlines()
    for line in lines:
      ret += "    %s\n" % (line)
    return ret

