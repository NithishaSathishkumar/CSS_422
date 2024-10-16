extern void _bzero( void*, int ); 
extern char* _strncpy( char*, char*, int );
extern void* _malloc( int );
extern void _free( void* );
extern void* _memcpy( );
extern void* _signal( int signum, void (*fn)(int) );
extern unsigned int _alarm( unsigned int );
//Extra Credit Driver 
//uncomment this part of the code to run the extra credit work
/*
extern int _strlen(const char*);
extern int _strcmp(const char*, const char*);
extern int _atoi(char* str);
extern void _strcpy(char* destination, const char* source);
*/

#define SIG_ALRM 14

//Extra Credit Driver 
//uncomment this part of the code to run the extra credit work
//#define RESULT_LOCATION ((char*)0x20000000)

int* alarmed;

void sig_handler1( int signum ) {
	*alarmed = 2;
}

void sig_handler2( int signum ) {
	*alarmed = 3;
}

int main( ) {
	char stringA[40] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabc\0";
  char stringB[40];
  //_bzero( stringB, 40 );
	_strncpy( stringB, stringA, 40 );
	_bzero( stringA, 40 );
  void* mem1 = _malloc( 1024 );
	void* mem2 = _malloc( 1024 );
	void* mem3 = _malloc( 8192 );
	void* mem4 = _malloc( 4096 );
	void* mem5 = _malloc( 512 );
	void* mem6 = _malloc( 1024 );
	void* mem7 = _malloc( 512 );
	_free( mem6 );
	_free( mem5 );
	_free( mem1 );
	_free( mem7 );
	_free( mem2 );
	void* mem8 = _malloc( 4096 );
	_free( mem4 );
	_free( mem3 );
	_free( mem8 );
	
	alarmed = (int *)_malloc( 4 );
	*alarmed = 1;
	_signal( SIG_ALRM, sig_handler1 );
	_alarm( 2 );
	while ( *alarmed != 2 ) {
		void* mem9 = _malloc( 4 );	
		_free( mem9 );		
	}
	
	_signal( SIG_ALRM, sig_handler2 );
	_alarm( 3 );
	while ( *alarmed != 3 ) {
		void* mem9 = _malloc( 4 );	
		_free( mem9 );
	}
	
	//Extra Credit Driver 
	//uncomment this part of the code to run the extra credit work
	/*
	char str1[] = "Hello, World!";
	char str2[] = "Hello, World!";
	char str3[] = "Hello, ARM!";
	
	int result1 = _strcmp(str1, str2); // result1 should be 0 (equal strings)
  int result2 = _strcmp(str1, str3); // result2 should be positive (str1 > str3)

    if (result1 == 0) {
			*((int*)0x20000000) = 1;
    } else { // If the strings are not equal
			*((int*)0x20000000) = 0;
		}
		
		if (result2 == 0) {
       *((int*)0x20000000) = 1;
    } else {
			*((int*)0x20000000) = 0; // If the strings are not equal
		}
		
		
    char source[] = "Hello, World!"; // Define source string
    
    // Define destination string
    char destination[50]; // Make sure it's large enough to hold the source string

    // Call the _strcpy function
    _strcpy(destination, source);

    // Store the result in the designated memory location
    for (int i = 0; i < 50; i++) {
        RESULT_LOCATION[i] = destination[i];
    }
		
		char str[] = "12345";
    int result = _atoi(str);
		int *resultptr = (int*)0x20000000; // Example memory address
    *resultptr = result;
		
		
		char string[] = "CSS422";
    int length = _strlen(string); // Call the _strlen function to get the length of the string
    // Store the result in memory
    int *result_ptr = (int*)0x20000000; // Example memory address
    *result_ptr = length;		
		*/
	return 0;
}