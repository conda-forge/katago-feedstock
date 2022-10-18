@echo On

if "%cuda_compiler_version%" == "None" (
    set KATAGO_BACKEND="EIGEN"
) else (
    set KATAGO_BACKEND="CUDA"

    REM this should move to nvcc-feedstock
    set "CUDA_PATH=%CUDA_PATH:\=/%"
    set "CUDA_HOME=%CUDA_HOME:\=/%"
    set CUDNN_INCLUDE_DIR=%LIBRARY_PREFIX%\include
)

:: Make a build folder and change to it.
cd cpp/

:: Configure using the CMakeFiles
cmake -G "NMake Makefiles" ^
      -DCMAKE_INSTALL_PREFIX:PATH="%LIBRARY_PREFIX%" ^
      -DCMAKE_PREFIX_PATH:PATH="%LIBRARY_PREFIX%" ^
      -DCMAKE_BUILD_TYPE:STRING=Release ^
      -DUSE_BACKEND="%KATAGO_BACKEND%" ^
      -DUSE_AVX2=1 ^
      -DNO_GIT_REVISION=1 ^
      .
if errorlevel 1 exit 1

:: Build!
nmake
if errorlevel 1 exit 1

:: Install binary
if not exist "%LIBRARY_BIN%" mkdir %LIBRARY_BIN%
copy katago.exe %LIBRARY_BIN%
if errorlevel 1 exit 1

:: Install config files
if not exist "%LIBRARY_PREFIX%\var\" mkdir "%LIBRARY_PREFIX%\var\"
xcopy /y /s /i configs %LIBRARY_PREFIX%\var\configs
if errorlevel 1 exit 1

:: Download latest NN
set KATAGO_WEIGTHS_DIR="%LIBRARY_PREFIX%\var\weights\"
set KATAGO_WEIGTHS_NAME="kata1-b40c256-s11840935168-d2898845681.bin.gz"
curl https://media.katagotraining.org/uploaded/networks/models/kata1/%KATAGO_WEIGTHS_NAME% --output %KATAGO_WEIGTHS_NAME%
if errorlevel 1 exit 1

if not exist "%KATAGO_WEIGTHS_DIR%" mkdir %KATAGO_WEIGTHS_DIR%
copy %KATAGO_WEIGTHS_NAME% %KATAGO_WEIGTHS_DIR%\%KATAGO_WEIGTHS_NAME%
if errorlevel 1 exit 1
