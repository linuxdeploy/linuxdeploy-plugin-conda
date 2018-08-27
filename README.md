# linuxdeploy-plugin-conda

Python plugin for linuxdeploy. Sets up miniconda inside an AppDir, and installs user-specified packages.


## Usage

```bash
> export CONDA_CHANNELS=mychannel CONDA_PACKAGES=mypackage
> ./linuxdeploy-x86_64.AppImage --appdir AppDir --plugin conda --output appimage --icon mypackage.png --desktop-file mypackage.desktop
```
