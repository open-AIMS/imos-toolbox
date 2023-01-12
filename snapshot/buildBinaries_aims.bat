
set CONDA=%USERPROFILE%\AppData\Local\Continuum\Anaconda3\condabin\conda
rem call %CONDA% activate "%USERPROFILE%\AppData\Local\Continuum\Anaconda3"
call %CONDA% activate IOOS

set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_351
set ANT_HOME=c:\opt\apache-ant-1.10.12
set MATLAB_ROOT="C:\Program Files\MATLAB\R2018b"

SET PATH=%ANT_HOME%\bin;%MATLAB_ROOT%\bin;%JAVA_HOME%\bin;%PATH%
python buildBinaries_aims.py
pause