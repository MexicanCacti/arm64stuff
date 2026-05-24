/*
Input = 1

Component           Double                   Float                    Comment
Value:              1                        1                        Delta(F - D): 0  Meaning no diff btwn approximations          
Sign:               0                        0                        
Exponent (hex):     3ff                      7f                       
De-biased (dec):    0                        0                        
Fraction (hex):     0                        0                        
Halves:             0                        0                        
Quarters:           0                        0                        
Eighths:            0                        0                        
Sixteenths:         0                        0                        
Thirty seconds:     0                        0                        
Full fraction:      0                        0                        
Equation:           1 x 2^0                  1 x 2^0

Sign -> 0 indicating positive
Exponents
3ff -> 1023     -> ~ 11 bits wide
7f  -> 127      -> ~ 8 bits wide
Sign bit for exponents implemented with offset... Anything above 1023/127 = positive, negative below

De-biased are vals of exponent w/ bias removed
Fraction has val of 0... 1 is always assumed to be the only value in front of the decimal place...
    Every floating point value is 1 plus a fraction all raised to some power of 2


Input 1.5
Component           Double                   Float                    Comment
Value:              1.5                      1.5                      Delta(F - D): 0               
Sign:               0                        0                        
Exponent (hex):     3ff                      7f                       
De-biased (dec):    0                        0                        
Fraction (hex):     8000000000000            400000                   
Halves:             1                        1                        
Quarters:           0                        0                        
Eighths:            0                        0                        
Sixteenths:         0                        0                        
Thirty seconds:     0                        0                        
Full fraction:      0.5                      0.5                      
Equation:           1.5 x 2^0                1.5 x 2^0  

Bit turned on in fraction, most significant bit, there is a half in 1.5

Input 1.875
Component           Double                   Float                    Comment
Value:              1.875                    1.875                    Delta(F - D): 0               
Sign:               0                        0                        
Exponent (hex):     3ff                      7f                       
De-biased (dec):    0                        0                        
Fraction (hex):     e000000000000            700000                   
Halves:             1                        1                        
Quarters:           1                        1                        
Eighths:            1                        1                        
Sixteenths:         0                        0                        
Thirty seconds:     0                        0                        
Full fraction:      0.875                    0.875                    
Equation:           1.875 x 2^0              1.875 x 2^0 

.5 + .25 + .125 = 0.875

Input: 8.51
Component           Double                   Float                    Comment
Value:              8.51                     8.510000229              Delta(F - D): 2.288818362e-07 
Sign:               0                        0                        
Exponent (hex):     402                      82                       
De-biased (dec):    3                        3                        
Fraction (hex):     1051eb851eb85            828f6                    
Halves:             0                        0                        
Quarters:           0                        0                        
Eighths:            0                        0                        
Sixteenths:         1                        1                        
Thirty seconds:     0                        0                        
Full fraction:      0.06375                  0.06375002861            
Equation:           1.06375 x 2^3            1.0637500286 x 2^3             
Equation:           1.0625 x 2^3             1.0625 x 2^3 

So 1/16 = 0.0625... 1 bit is always set... so eq is going to be...
1.0625 x 2^3
    Since 2^3 == 8
    If we did the half bit we would get: 1.5 x 2^3... which would be wrong!

Input 8.5
Component           Double                   Float                    Comment
Value:              8.5                      8.5                      Delta(F - D): 0               
Sign:               0                        0                        
Exponent (hex):     402                      82                       
De-biased (dec):    3                        3                        
Fraction (hex):     1000000000000            80000                    
Halves:             0                        0                        
Quarters:           0                        0                        
Eighths:            0                        0                        
Sixteenths:         1                        1                        
Thirty seconds:     0                        0                        
Full fraction:      0.0625                   0.0625                   
Equation:           1.0625 x 2^3             1.0625 x 2^3 


Now lets take a NaN...
This is true when (for a float) The exponent is 0xFF and the fraction is not zero
Using sqrt(-1)).
sign: 0
exp:  ff debiased: 128
frac: 0400000
NaN:  1
Inf:  0
Can't get a float that is 2^128 since that value is reserved for NaN and Inf

Now lets take a INF....
Dividing by zero.
sign: 1
exp:  ff debiased: 128
frac: 0000000
NaN:  0
Inf:  1

exp: 0xFF and the fraction is fully zero. Sign signfies pos/neg infinity

Testing for NNaN and Inf can be done with the following functions:
isnan(floating point value)
isinf(floating point value)
(Work for float & Double)

Once a var goes NaN or Inf, subsequent ops remain NaN or INF

*/

/*	Perry Kivolowitz
    A Gentle Introduction to Assembly Language
*/

#include <iostream>
#include <iomanip>
#include <string>
#include <sstream>
#include <cstdlib>
#include <cmath>

using namespace std;

const int BIASD = 1023;     // biasing value for double exponents
const int BIASF = 127;      // biasing value for floats

// The mantissa controls precision.

const int FRAC_SIZD = 52;   // number of bits in double's mantissa
const int FRAC_SIZF = 23;   // number of bits in float's mantissa

// The exponent controls range.

const int EXPO_SIZD = 11;   // number of bits in a double's exponent
const int EXPO_SIZF = 8;    // number of bits in a float's exponent

const int SIGN_SIZE = 1;

struct SP {                 // construction of a float
	unsigned int frac : FRAC_SIZF;
	unsigned int expo : EXPO_SIZF;
	unsigned int sign : SIGN_SIZE;
};

struct DP {                 // construction of a double
	unsigned long frac : FRAC_SIZD;
	unsigned long expo : EXPO_SIZD;
	unsigned long sign : SIGN_SIZE;
};

union Double {
	double d;
	DP D;
};

union Single {
	float f;
	SP F;
};

double DeBinary(bool is_double, unsigned long frac) {
	double f = 0.0f;
	int bits = (is_double ? FRAC_SIZD : FRAC_SIZF);

	for (int i = 0; i < bits; i++) {
		if (frac & ((unsigned long)(1) << (bits - 1 - i))) {
			f += 1.0f / double((unsigned long)(1) << (i + 1));
		}
	}
	return f;
}

template<class T>
string MakeEquation(T & u, int bias) {
	stringstream ss;
	bool is_double = (bias == BIASD);
	ss << (u.sign ? "-" : "") << dec << setprecision(11);
    ss << 1.0 + DeBinary(is_double, u.frac);
    ss << " x 2^" << (u.expo - bias);
	return ss.str();
}

int main(int argc, char ** argv) {
	Double d;
	Single  f;

	const int fore_space = 18;
	const int field_space = 20;

	if (argc < 2) {
		cerr << "Requires a floating point value on command line .\n";
		return 1;
	}
	d.d = atof(argv[1]);
	f.f = float(d.d);

	cout << left << setw(fore_space) << "Component" << left;
    cout << setw(field_space);
    cout << "Double" << left << setw(field_space) << "Float";
    cout << "Comment" << endl;

	cout << left << setw(fore_space) << "Value:" << setw(field_space);
    cout << setprecision(10) << d.d;
	cout << setw(field_space) << setprecision(10) << f.f;
	cout << "Delta(F - D): " << setw(16) << setprecision(10);
    cout << f.f - d.d << endl;

	cout << left << setw(fore_space) << "Sign:";
	cout << setw(field_space) << (bool)d.D.sign;
	cout << setw(field_space) << (bool)f.F.sign;
	cout << endl;

	cout << setw(fore_space) << "Exponent (hex):";
	cout << setw(field_space) << hex << d.D.expo;
	cout << setw(field_space) << hex << f.F.expo;
	cout << endl;

	cout << setw(fore_space) << "De-biased (dec):";
	cout << setw(field_space) << dec << d.D.expo - BIASD;
	cout << setw(field_space) << dec << f.F.expo - BIASF;
	cout << endl;

	cout << setw(fore_space) << "Fraction (hex):";
	cout << setw(field_space) << hex << d.D.frac;
	cout << setw(field_space) << hex << f.F.frac;
	cout << endl;

	cout << setw(fore_space) << "Halves:";
	cout << setw(field_space) << hex;
    cout << ((d.D.frac >> (FRAC_SIZD - 1)) & 1);
	cout << setw(field_space) << hex;
    cout << ((f.F.frac >> (FRAC_SIZF - 1)) & 1);
	cout << endl;

	cout << setw(fore_space) << "Quarters:";
	cout << setw(field_space) << hex;
    cout << ((d.D.frac >> (FRAC_SIZD - 2)) & 1);
	cout << setw(field_space) << hex;
    cout << ((f.F.frac >> (FRAC_SIZF - 2)) & 1);
	cout << endl;

	cout << setw(fore_space) << "Eighths:";
	cout << setw(field_space) << hex;
    cout << ((d.D.frac >> (FRAC_SIZD - 3)) & 1);
	cout << setw(field_space) << hex;
    cout << ((f.F.frac >> (FRAC_SIZF - 3)) & 1);
	cout << endl;

	cout << setw(fore_space) << "Sixteenths:";
	cout << setw(field_space) << hex;
    cout << ((d.D.frac >> (FRAC_SIZD - 4)) & 1);
	cout << setw(field_space) << hex;
    cout << ((f.F.frac >> (FRAC_SIZF - 4)) & 1);
	cout << endl;

	cout << setw(fore_space) << "Thirty seconds:";
	cout << setw(field_space) << hex;
    cout << ((d.D.frac >> (FRAC_SIZD - 5)) & 1);
	cout << setw(field_space) << hex;
    cout << ((f.F.frac >> (FRAC_SIZF - 5)) & 1);
	cout << endl;

	cout << setw(fore_space) << "Full fraction:";
	cout << setw(field_space) << dec << DeBinary(true,  d.D.frac);
	cout << setw(field_space) << dec << DeBinary(false, f.F.frac);
	cout << endl;

	cout << setw(fore_space) << "Equation:";
	cout << setw(field_space) << dec << MakeEquation<DP>(d.D, BIASD);
	cout << setw(field_space) << dec << MakeEquation<SP>(f.F, BIASF);
	cout << endl;

	return 0;
}