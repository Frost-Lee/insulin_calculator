all: undistort.so

clean:
	rm -f *.so *.o

undistort.so: undistort.c
	cc -fPIC -shared -o undistort.so undistort.c
