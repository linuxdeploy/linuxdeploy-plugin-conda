#! /bin/bash

# abort on all errors
set -e

if [ "$DEBUG" != "" ]; then
    set -x
fi

script=$(readlink -f "$0")

show_usage() {
    echo "Usage: $script --appdir <path to AppDir>"
    echo
    echo "Bundles software available as conda packages into an AppDir"
    echo
    echo "Variables:"
    echo "  CONDA_CHANNELS=\"channelA;channelB;...\""
    echo "  CONDA_PACKAGES=\"packageA;packageB;...\""
    echo "  CONDA_PYTHON_VERSION=\"3.6\""
    echo "  PIP_REQUIREMENTS=\"packageA packageB -r requirements.txt -e git+https://...\""
    echo "  PIP_PREFIX=\"AppDir/usr/share/conda\""
    echo "  ARCH=\"x86_64\" (further supported values: i686)"
}

log() {
    [[ "$TERM" != "" ]] && tput setaf 3
    [[ "$TERM" != "" ]] && tput bold
    echo -*- "$@"
    [[ "$TERM" != "" ]] && tput sgr0
}

APPDIR=

while [ "$1" != "" ]; do
    case "$1" in
        --plugin-api-version)
            echo "0"
            exit 0
            ;;
        --appdir)
            APPDIR="$2"
            shift
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            log "Invalid argument: $1"
            log
            show_usage
            exit 1
            ;;
    esac
done

if [ "$APPDIR" == "" ]; then
    show_usage
    exit 1
fi

mkdir -p "$APPDIR"

if [ "$CONDA_PACKAGES" == "" ]; then
    log "WARNING: \$CONDA_PACKAGES not set, no packages will be installed!"
fi

# the user can specify a directory into which the conda installer is downloaded
# if they don't specify one, we use a temporary directory with a predictable name to preserve downloaded files across runs
# this should reduce the download overhead
# if one is specified, the installer will not be re-downloaded unless it has changed
if [ "$CONDA_DOWNLOAD_DIR" != "" ]; then
    # resolve path relative to cwd
    if [[ "$CONDA_DOWNLOAD_DIR" != /* ]]; then
        CONDA_DOWNLOAD_DIR="$(readlink -f "$CONDA_DOWNLOAD_DIR")"
    fi

    log "Using user-specified download directory: $CONDA_DOWNLOAD_DIR"
else
    # create temporary directory into which downloaded files are put
    CONDA_DOWNLOAD_DIR="/tmp/linuxdeploy-plugin-conda-$(whoami)"

    log "Using default temporary download directory: $CONDA_DOWNLOAD_DIR"
fi

# make sure the directory exists
mkdir -p "$CONDA_DOWNLOAD_DIR"

if [ -d "$APPDIR"/usr/conda ]; then
    log "WARNING: conda prefix directory exists: $APPDIR/usr/conda"
    log "Please make sure you perform a clean build before releases to make sure your process works properly."
fi

ARCH=${ARCH:-x86_64}

# install Miniconda, a self contained Python distribution, into AppDir
case "$ARCH" in
    "x86_64")
        miniconda_installer_filename=Miniconda3-latest-Linux-x86_64.sh
        ;;
    "i386"|"i686")
        miniconda_installer_filename=Miniconda3-latest-Linux-x86.sh
        ;;
    *)
        log "ERROR: Unknown Miniconda arch: $ARCH"
        exit 1
        ;;
esac

pushd "$CONDA_DOWNLOAD_DIR"
    miniconda_url=https://repo.continuum.io/miniconda/"$miniconda_installer_filename"
    # let's make sure the file exists before we then rudimentarily ensure mutual exclusive access to it with flock
    # we set the timestamp to epoch 0; this should likely trigger a redownload for the first time
    touch "$miniconda_installer_filename" -d '@0'

    # now, let's download the file
    flock "$miniconda_installer_filename" wget -N -c "$miniconda_url"
popd

# install into usr/conda/ instead of usr/ to make sure that the libraries shipped with conda don't overwrite or
# interfere with libraries bundled by other plugins or linuxdeploy itself
bash "$CONDA_DOWNLOAD_DIR"/"$miniconda_installer_filename" -b -p "$APPDIR"/usr/conda -f

# activate environment
. "$APPDIR"/usr/conda/bin/activate

# we don't want to touch the system, therefore using a temporary home
mkdir -p _temp_home
export HOME=$(readlink -f _temp_home)

# conda-forge is used by many conda packages, therefore we'll add that channel by default
conda config --add channels conda-forge

# force-install libxi, required by a majority of packages on some more annoying distributions like e.g., Arch
#conda install -y xorg-libxi

# force another python version if requested
if [ "$CONDA_PYTHON_VERSION" != "" ]; then
    conda install -y python="$CONDA_PYTHON_VERSION"
fi

# add channels specified via $CONDA_CHANNELS
IFS=';' read -ra chans <<< "$CONDA_CHANNELS"
for chan in "${chans[@]}"; do
    conda config --append channels "$chan"
done

# install packages specified via $CONDA_PACKAGES
IFS=';' read -ra pkgs <<< "$CONDA_PACKAGES"
for pkg in "${pkgs[@]}"; do
    conda install -y "$pkg"
done

# install requirements from PyPI specified via $PIP_REQUIREMENTS
if [ "$PIP_REQUIREMENTS" != "" ]; then
    if [ "$PIP_WORKDIR" != "" ]; then
        pushd "$PIP_WORKDIR"
    fi

    pip install -U $PIP_REQUIREMENTS ${PIP_PREFIX:+--prefix=$PIP_PREFIX} ${PIP_VERBOSE:+-v}

    if [ "$PIP_WORKDIR" != "" ]; then
        popd
    fi
fi

# create symlinks for all binaries in usr/conda/bin/ in usr/bin/
mkdir -p "$APPDIR"/usr/bin/
pushd "$APPDIR"
for i in usr/conda/bin/*; do
    if [ -f usr/bin/"$(basename "$i")" ]; then
        log "WARNING: symlink exists, will not be touched: usr/bin/$i"
    else
        ln -s ../../"$i" usr/bin/
    fi
done
popd


# remove bloat
if [ "$CONDA_SKIP_CLEANUP" == "" ]; then
    pushd "$APPDIR"/usr/conda
    rm -rf pkgs
    find -type d -iname '__pycache__' -print0 | xargs -0 rm -r
    find -type f -iname '*.so*' -print -exec strip '{}' \;
    find -type f -iname '*.a' -print -delete
    rm -rf lib/cmake/
    rm -rf share/{gtk-,}doc
    rm -rf share/man
    rm -rf lib/python?.?/site-packages/{setuptools,pip}
    popd
fi

