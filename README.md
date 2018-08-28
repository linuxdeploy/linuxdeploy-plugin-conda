# linuxdeploy-plugin-conda

Python plugin for linuxdeploy. Sets up miniconda inside an AppDir, and installs user-specified packages.


## Usage

```bash
> export CONDA_CHANNELS=mychannel CONDA_PACKAGES=mypackage
> ./linuxdeploy-x86_64.AppImage --appdir AppDir --plugin conda --output appimage --icon mypackage.png --desktop-file mypackage.desktop
```

## Example

This generates a working FreeCAD AppImage from Conda ingredients, including Qt and PyQt:

```
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
