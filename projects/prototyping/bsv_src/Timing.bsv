package Timing;


/******************************************************
* TIMING
******************************************************/
Integer f_sys       = 100 * (10**6); // 100MHz

Integer c_10NS      = 10   * f_sys / 10**9; // max resolution (1 cycle)
Integer c_US        = 100  * c_10NS;
Integer c_MS        = 1000 * c_US;
Integer c_S         = 1000 * c_MS;


endpackage
