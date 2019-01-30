#!/bin/bash

set -ex

BLACK_VERSION=18.9b0
MYPY_VERSION=0.660

pip install -U pip setuptools wheel

if [ "$CHECK_FORMATTING" = "1" ]; then
    pip install black==${BLACK_VERSION}
    if ! black --check setup.py async_generator-stubs outcome-stubs trio-stubs trio_typing; then
        cat <<EOF
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Formatting problems were found (listed above). To fix them, run

   pip install black==${BLACK_VERSION}
   black setup.py async_generator-stubs outcome-stubs trio-stubs trio_typing

in your local checkout.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOF
        exit 1
    fi
    exit 0
fi

if [ "$CHECK_TYPING" = "1" ]; then
    pip install mypy==${MYPY_VERSION}
    pip install -Ur test-requirements.txt
    mkdir empty; cd empty
    ln -s ../async_generator-stubs async_generator
    ln -s ../outcome-stubs outcome
    ln -s ../trio-stubs trio
    ln -s ../trio_typing trio_typing
    mypy --strict -p async_generator -p outcome -p trio -m trio_typing -m trio_typing.plugin
    exit $?
fi

python setup.py sdist --formats=zip
pip install dist/*.zip

if [ "$CHECK_DOCS" = "1" ]; then
    pip install -Ur ci/rtd-requirements.txt
    cd docs
    # -n (nit-picky): warn on missing references
    # -W: turn warnings into errors
    sphinx-build -nW  -b html source build
else
    # Actual tests
    pip install -Ur test-requirements.txt

    mkdir empty
    cd empty

    pytest -W error -ra -v -p trio_typing._tests.datadriven --pyargs trio_typing
fi
