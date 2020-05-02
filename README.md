# linuxdeploy-plugin-conda

Python plugin for linuxdeploy. Sets up miniconda inside an AppDir, and installs user-specified packages.


## Usage

```bash
# get linuxdeploy and linuxdeploy-plugin-conda (see below for more information)
# configure environment variables which control the plugin's behavior
> export CONDA_CHANNELS=mychannel;myotherchannel CONDA_PACKAGES=mypackage;myotherpackage
# call through linuxdeploy
> ./linuxdeploy-x86_64.AppImage --appdir AppDir --plugin conda --output appimage --icon mypackage.png --desktop-file mypackage.desktop
```

There are many variables available to alter the behavior of the plugin. The current list can be obtained by calling the plugin with `--help`.


## Customize caching behavior

By default, linuxdeploy-plugin-conda redownloads the miniconda installer on every execution. This is not an issue for most people, as the installers are only 50-80 MiB in size. However, it is usually not necessary to redownload the file every time, especially while developing scripts based on the conda plugin.

Therefore, you can set a custom directory via the environment variable `$CONDA_DOWNLOAD_DIR`, into which downloaded files are stored then. The plugin makes use of some `wget` parameters to ensure that the file is only downloaded when it is incomplete (`-c`) or there is a newer version available (`-N`).

Example:

```bash
> export CONDA_DOWNLOAD_DIR=/my/own/directory
> ./linuxdeploy-x86_64.AppImage --plugin conda [...]
[...]
Using user-specified download directory: /my/own/directory
[...]
```

Relative paths work as well.



## Example

This generates a working FreeCAD AppImage from Conda ingredients, including Qt and PyQt:

```bash
wget -c "https://raw.githubusercontent.com/TheAssassin/linuxdeploy-plugin-conda/master/linuxdeploy-plugin-conda.sh"
wget -c "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
chmod +x linuxdeploy-x86_64.AppImage linuxdeploy-plugin-conda.sh

cat > freecad.desktop <<\EOF
[Desktop Entry]
Version=1.0
Name=FreeCAD
Name[de]=FreeCAD
Comment=Feature based Parametric Modeler
Comment[de]=Feature-basierter parametrischer Modellierer
GenericName=CAD Application
GenericName[de]=CAD-Anwendung
Exec=FreeCAD %F
Terminal=false
Type=Application
Icon=freecad
Categories=Graphics;Science;Engineering;
StartupNotify=true
GenericName[de_DE]=Feature-basierter parametrischer Modellierer
Comment[de_DE]=Feature-basierter parametrischer Modellierer
MimeType=application/x-extension-fcstd;
EOF

export CONDA_CHANNELS=freecad CONDA_PACKAGES=freecad
./linuxdeploy-x86_64.AppImage --appdir AppDir -i AppDir/usr/conda/data/Mod/Start/StartPage/freecad.png -d freecad.desktop --plugin conda --output appimage
```

## Projects using linuxdeploy-plugin-conda

[Projects on GitHub that are using linuxdeploy-plugin-conda](https://github.com/search?l=Shell&q=linuxdeploy-plugin-conda&type=Code)
