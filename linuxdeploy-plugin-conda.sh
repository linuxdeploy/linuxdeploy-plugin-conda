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
            echo "Invalid argument: $1"
            echo
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
    echo "WARNING: \$CONDA_PACKAGES not set, no packages will be installed!"
fi


# create temporary directory into which downloaded files are put
TMPDIR=$(mktemp -d)

_cleanup() {
    rm -rf "$TMPDIR"
}

trap _cleanup EXIT

if [ -d "$APPDIR"/usr/conda ]; then
    echo "Error: directory exists: $APPDIR/usr/conda"
    exit 1
fi

# install Miniconda, a self contained Python distribution, into AppDir
(cd "$TMPDIR" && wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh)

# install into usr/conda/ instead of usr/ to make sure that the libraries shipped with conda don't overwrite or
# interfere with libraries bundled by other plugins or linuxdeploy itself
bash "$TMPDIR"/Miniconda3-latest-Linux-x86_64.sh -b -p "$APPDIR"/usr/conda -f

# activate environment
. "$APPDIR"/usr/conda/bin/activate

# conda-forge is used by many conda packages, therefore we'll add that channel by default
conda config --add channels conda-forge

# force-install libxi, required by a majority of packages on some more annoying distributions like e.g., Arch
#conda install -y xorg-libxi

# force another python version if requested
if [ "$CONDA_PYTHON_VERSION" != "" ]; then
    conda install -y python="$CONDA_PYTHON_VERSION"
fi

# add channels specified via $CONDA_CHANNELS
IFS=';' read -ra pkgs <<< "$CONDA_CHANNELS"
for chan in "${chans[@]}"; do
    conda config --add channels "$chan"
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

    pip_args=('--prefix="$APPDIR/usr/conda/"')
    if [ "$PIP_VERBOSE" != "" ]; then
        pip_args+=("-v")
    fi

    pip install -U $PIP_REQUIREMENTS "${pip_args[@]}"

    if [ "$PIP_WORKDIR" != "" ]; then
        popd
    fi
fi

# create symlinks for all binaries in usr/conda/bin/ in usr/bin/
mkdir -p "$APPDIR"/usr/bin/
for i in "$APPDIR"/usr/conda/bin/*; do
    ln -s -r "$i" "$APPDIR"/usr/bin/
done

# remove bloat
pushd "$APPDIR"/usr/conda
rm -rf pkgs
find -type d -iname '__pycache__' -print0 | xargs -0 rm -r
find -type f -iname '*.so*' -print -exec strip '{}' \;
find -type f -iname '*.a' -print -delete
rm -rf lib/cmake/
rm -rf include/
rm -rf share/{gtk-,}doc
