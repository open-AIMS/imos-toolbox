rem setlocal
set CONDA=%USERPROFILE%\AppData\Local\Continuum\Anaconda3\condabin\conda
call %CONDA% activate "%USERPROFILE%\AppData\Local\Continuum\Anaconda3"

set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_271
set ANT_HOME=c:\opt\apache-ant-1.10.9
set MATLAB_ROOT="C:\Program Files\MATLAB\R2018b"

SET PATH=%ANT_HOME%\bin;%MATLAB_ROOT%\bin;%JAVA_HOME%\bin;%PATH%

python build_aims.py --arch=win64 --mat_path=%MATLAB_ROOT%\bin\matlab