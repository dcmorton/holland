#!/bin/bash

VERSION=$(python setup.py --version)
PREFIX=holland-${VERSION}
TARBALL=${PREFIX}.tar.gz
git archive --prefix=${PREFIX}/ HEAD | gzip -9 > ${TARBALL}
