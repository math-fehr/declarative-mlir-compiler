#!/usr/bin/python3

import os
import time
import sys

cwd = os.path.dirname(os.path.realpath(__file__))

def time_taken(command):
    time1 = time.time()
    os.system(command)
    return time.time() - time1

def test_file(filename, n):
    os.system("./luac.py benchmarks/%s.lua > benchmarks/build/%s.mlir" % (filename, filename))
    os.system("mlir-translate --mlir-to-llvmir benchmarks/build/%s.mlir -o benchmarks/build/%s.ll" % (filename, filename))
    os.system("clang++ benchmarks/build/%s.ll impl.cpp builtins.cpp -O2 -std=c++17 -o benchmarks/bin/%s -Wno-override-module" % (filename, filename))
    print(filename)
    time1 = 0
    for i in range(n):
        time1 += time_taken("./benchmarks/bin/%s > /dev/null" % filename)
    print("luac.py: %s s" % time1)
    time2 = 0
    for i in range(n):
        time2 += time_taken("luajit -O3 ./benchmarks/%s.lua > /dev/null" % filename)
    print("luajit:  %s s" % time2)

if __name__ == '__main__':
    n = 1
    if len(sys.argv) >= 2:
        n = int(sys.argv[1])

    filenames = [filename[:-4] for filename in os.listdir("benchmarks/") if filename[-4:] == ".lua"]
    os.system("mkdir -p benchmarks/bin")
    os.system("mkdir -p benchmarks/build")

    for filename in filenames:
        test_file(filename, n)
