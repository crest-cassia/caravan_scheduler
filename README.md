# CARAVAN Scheduler

[![Travis](https://img.shields.io/travis/crest-cassia/caravan_scheduler/master.svg)](https://travis-ci.org/crest-cassia/caravan_scheduler)

The scheduler part of [CARAVAN](https://github.com/crest-cassia/caravan) framework.

## Building the scheduler

You need an X10 compiler as a prerequisite. Run the following scripts.

```
./build.sh
```

By default, "Socket" is selected as X10RT. If you are going to build an MPI-backed program, set environment variable "IS\_MPI" to "1" when building it.

```
env IS_MPI=1 ./build.sh
```

The executables are built in the `build/` directory.

## Running tests

Run `test/build.sh` and executes it.

```
cd test
./build.sh
./build/a.out
```

## License

See [LICENSE](LICENSE).

