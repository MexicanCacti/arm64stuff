
#include <random>
#include <iostream>
#include <ctime>
#include <typeinfo>
using namespace std;


int main(){

    auto rand = RAND_MAX;
    cout << rand << endl;

    time_t t = time(NULL);
    cout << typeid(t).name() << endl;
    cout << sizeof(t) << endl;
    return 0;
}