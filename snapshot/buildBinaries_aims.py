#!/usr/bin/python

import os
import sys
import time
import shutil

# buildBinaries.py
# Exports the IMOS Toolbox from SVN and
#
#   - Runs Util/imosCompile.m to create a ddb.jar and imosToolbox executables
# 
# Both of these files are copied to the relevant directory and commited to SVN.
#
# python, git, javac, ant and matlab must be on PATH
# JAVA_HOME must be set
#

lt = time.localtime()

project = 'imos-toolbox'

version    = 'AIMS-2.5.41'

#url        = 'https://github.com/aodn/%s.git' % project
url = 'file:///C:/Projects/aims-gitlab/%s/.git' % project
exportDir  = 'export'

compilerLog = '.\%s\log.txt' % exportDir

#
# export from SVN
#
print('\n--exporting tree from %s to %s' % (url, exportDir))
os.system('git clone %s %s' % (url, exportDir))
os.system('cd %s && git checkout %s' % (exportDir, version))

#
# remove snapshot directory
#
print('\n--removing snapshot')
shutil.rmtree('%s/snapshot' % exportDir)

#
# build DDB interface
#
print('\n--building DDB interface')
compiled = os.system('cd %s/Java && C:/opt/apache-ant-1.10.5/bin/ant.bat install' % exportDir)

if compiled is not 0:
  print('\n--DDB interface compilation failed - cleaning')
  os.system('cd %s/Java && C:/opt/apache-ant-1.10.5/bin/ant.bat clean' % exportDir)

#
# create snapshot
#
print('\n--building Matlab binaries')
matlabExe='\"C:/Program Files/MATLAB/R2017b/bin\matlab.exe\"'
matlabOpts = '-nodisplay -wait -logfile "%s"' % compilerLog
matlabCmd = 'addpath(\'Util\'); try, imosCompile(\'%s\'); exit(); catch e, disp(e.message); end;' % version
#os.system('cd %s && matlab %s -r "%s"' % (exportDir, matlabOpts, matlabCmd))
os.system('cd %s && %s %s -r "%s"' % (exportDir, matlabExe, matlabOpts, matlabCmd))

print('\n--removing local git tree')
shutil.rmtree('%s' % exportDir)
