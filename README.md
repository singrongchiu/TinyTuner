# TinyTuner
## Overview
A small device that can tell you the dominant frequency. Code is used with a PDM microphone and a 7segment display. 

## Testing
N = 64 point FFT working shown in the following testbench: 
https://www.edaplayground.com/x/M8Zf

Note that the output from that FFT is not bit reversed  
output 000 -> bin 000  
output 001 -> bin 100  
output 010 -> bin 010  
output 011 -> bin 110  
output 100 -> bin 001  
output 101 -> bin 101  
output 110 -> bin 011  
output 111 -> bin 111  

## Acknowledgements
Butterfly operations based on:
https://arishalreja.github.io/projects/fftprocessor/
