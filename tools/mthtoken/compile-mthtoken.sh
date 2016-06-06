# compile script of MthToken with Ansi-C compile available at command line
#
# The standard compile of mthtoken (a single c source file)
# if gcc is not installed, try 'cc'  

# cc -v -o mthtoken mthtoken.c     # -v = verbose compile
gcc -o mthtoken mthtoken.c
ls -lh mthtoken
