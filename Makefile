# See LICENSE.txt for license details.

CXX_FLAGS += -std=c++11 -O3 -Wall
PAR_FLAG = -fopenmp
BUILD_RAPL = Yes

ifneq (,$(findstring icpc,$(CXX)))
	PAR_FLAG = -openmp
endif

ifneq (,$(findstring sunCC,$(CXX)))
	CXX_FLAGS = -std=c++11 -xO3 -m64 -xtarget=native
	PAR_FLAG = -xopenmp
endif

ifneq ($(SERIAL), 1)
	CXX_FLAGS += $(PAR_FLAG)
endif

KERNELS = bc bfs cc pr sssp tc
SUITE = $(KERNELS) converter
ifeq ($(BUILD_RAPL), Yes)
	PAPI_HOME=/usr/local/packages/papi/git
	CFLAGS += -I$(PAPI_HOME)/include -DPOWER_PROFILING=1 -g -Wall
	CXX_FLAGS += -DPOWER_PROFILING=1
	LDLIBS += -L$(PAPI_HOME)/lib -Wl,-rpath,$(PAPI_HOME)/lib -lpapi -lm
endif

.PHONY: all
all: $(SUITE) sleep_baseline

% : %.o power_rapl.o
	$(CXX) $(CXX_FLAGS) -o $@ power_rapl.o $< $(LDLIBS)

%.o : src/%.cc src/*.h power_rapl.h
	$(CXX) $(CXX_FLAGS) -c $< -o $@

sleep_baseline: power_rapl.o sleep_baseline.o
	$(CC) $(CFLAGS) -o baseline sleep_baseline.o power_rapl.o $(LDLIBS)
power_rapl.o : power_rapl.c power_rapl.h
	$(CC) $(CFLAGS) -c -o power_rapl.o power_rapl.c $(LDLIBS) 
sleep_baseline.o: sleep_baseline.c
	$(CC) -c -o sleep_baseline.o sleep_baseline.c

# Testing
include test/test.mk

.PHONY: clean
clean:
	rm -f $(SUITE) power_rapl.o sleep_baseline.o sleep_baseline test/out/* $(SUITE:=.o)
