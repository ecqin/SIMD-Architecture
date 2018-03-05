# SIMD-Architecture


To run the Harmonica RTL Project:

  1. SSH to ecelinsrvx.ece.gatech.edu
  2. source /tools/mentor/modelsim/ms106a/cshrc.modelsim
  3. vsim &
  4. File -> New -> Project (Enter a project name and press OK)
  5. Add Existing File (Add all of the *.sv file from the src directory)
  6. Compile -> Compile All
  7. VSIM 2 > do ../scripts/sig_gen 
  8. Remove all signals from the waveform
  9. VSIM 2 > do ../scripts/sig_debug
  10. Look at the generated tracker files and waveform.
  
