#!/usr/bin/python3

import os

def test_file(filename):
    os.system("./luac.py tests/%s.lua > tests/build/%s.mlir" % (filename, filename))
    os.system("mlir-translate --mlir-to-llvmir tests/build/%s.mlir -o tests/build/%s.ll" % (filename, filename))
    os.system("clang++ tests/build/%s.ll impl.cpp builtins.cpp -O2 -std=c++17 -o tests/bin/%s -Wno-override-module" % (filename, filename))
    os.system("./tests/bin/%s > tests/build/%s.out" % (filename, filename))
    os.system("diff tests/build/%s.out tests/%s.out" % (filename, filename))
    return

if __name__ == '__main__':
    filenames = [filename[:-4] for filename in os.listdir("tests/") if filename[-4:] == ".lua"]
    os.system("mkdir -p tests/bin")
    os.system("mkdir -p tests/build")

    for filename in filenames:
        test_file(filename)
