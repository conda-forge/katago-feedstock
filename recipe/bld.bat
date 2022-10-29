@echo On

if "%cuda_compiler_version%" == "None" (
    set KATAGO_BACKEND="EIGEN"
    set USE_CUDA=0
) else (

    set KATAGO_BACKEND="CUDA"

    echo CUDA_HOME: %CUDA_HOME%
    echo CUDA_PATH: %CUDA_PATH%

    set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%cuda_compiler_version%
    set CUDNN_INCLUDE_DIR=%LIBRARY_PREFIX%\include

    echo CUDA_PATH (after): %CUDA_PATH%

    set CC="cl.exe "
    set CXX="cl.exe "
)

SET CMAKE_GENERATOR=Ninja
SET CMAKE_GENERATOR_PLATFORM=
SET CMAKE_GENERATOR_TOOLSET=
SET VERBOSE=ON

:: Make a build folder and change to it.
cd cpp/

:: Configure using the CMakeFiles
cmake -G "Ninja" ^
      -DCMAKE_INSTALL_PREFIX:PATH="%LIBRARY_PREFIX%" ^
      -DCMAKE_PREFIX_PATH:PATH="%LIBRARY_PREFIX%" ^
      -DCMAKE_BUILD_TYPE:STRING=Release ^
      -DUSE_BACKEND="%KATAGO_BACKEND%" ^
      -DUSE_AVX2=1 ^
      -DNO_GIT_REVISION=1 ^
      %CMAKE_ARGS% ^
      .
if errorlevel 1 exit 1

:: Build!
cmake --build . --config Release
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


