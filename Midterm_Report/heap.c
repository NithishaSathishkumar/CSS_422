/*
 * Nithisha Sathishkumar
 * May 17, 2024
 * This is a C implementation of malloc( ) and free( ), based on the buddy
 * memory allocation algorithm. 
 */
#include <stdio.h> // printf
#define MIN_CHUNK_SIZE 32
#define BIT_CLEAR_MASK 0x0001
#define SIZE_CLEAR_MASK 0x1F
#define ADDRESS_LOCATION 0x01
#define CHUNK_SIZE 16

/*
 * The following global variables are used to simulate memory allocation
 * Cortex-M's SRAM space.
 */

// Heap
char array[0x8000];            // simulate SRAM: 0x2000.0000 - 0x2000.7FFF
int heap_top   = 0x20001000;   // the top of heap space
int heap_bot   = 0x20004FE0;   // the address of the last 32B in heap
int max_size   = 0x00004000;   // maximum allocation: 16KB = 2^14
int min_size   = 0x00000020;   // minimum allocation: 32B = 2^5

// Memory Control Block: 2^10B = 1KB space
int mcb_top    = 0x20006800;   // the top of MCB
int mcb_bot    = 0x20006BFE;   // the address of the last MCB entry
int mcb_ent_sz = 0x00000002;   // 2B per MCB entry
int mcb_total  = 512;          // # MCB entries: 2^9 = 512 entries

/*
 * Convert a Cortex SRAM address to the corresponding array index.
 * @param  sram_addr address of Cortex-M's SRAM space starting at 0x20000000.
 * @return array index.
 */
int m2a( int sram_addr ) {
  int index = sram_addr - 0x20000000;
  return index;
}

/*
 * Reverse an array index back to the corresponding Cortex SRAM address.
 * @param  array index.
 * @return the corresponding Cortex-M's SRAM address in an integer.
 */ 
int a2m( int array_index ) {
  return array_index + 0x20000000;
}

/*
 * In case if you want to print out, all array elements that correspond
 * to MCB: 0x2006800 - 0x20006C00.
 */
void printArray( ) {
  printf( "memroy ............................\n" );
  for (int i = 0; i < 0x8000; i += 4){
    if ( a2m(i) >= 0x20006800) {
	    printf( "%x = %x(%d)\n", a2m(i), *(int *)&array[i], *(int *)&array[i] ); 
    }
  }
}

/*
 * _ralloc is _kalloc's helper function that is recursively called to
 * allocate a requested space, using the buddy memory allocaiton algorithm.
 * Implement it by yourself in step 1.
 *
 * @param  size  the size of a requested memory space
 * @param  left  the address of the left boundary of MCB entries to examine
 * @param  right the address of the right boundary of MCB entries to examine
 * @return the address of Cortex-M's SRAM space. While the computation is
 *         made in integers, cast it to (void *). The gcc compiler gives
 *         a warning sign:
                cast to 'void *' from smaller integer type 'int'
 *         Simply ignore it.
 */
void *_ralloc(int size, int left, int right) {
    int total_space = right - left + mcb_ent_sz; // Calculate the size of the entire space including metadata
    int half_space = total_space / 2; // Calculate half of the entire space
    int mid = left + half_space; // Calculate the midpoint of the space
    int actual_total_size = total_space * CHUNK_SIZE;// Calculate the size of the entire space including metadata (in bytes)
    int actual_half_size = half_space * CHUNK_SIZE;  // Calculate half of the entire space (in bytes)
    void* heap_location = NULL;  // Initialize heap address to NULL

    //Check if requested size fits in the left half of the space
    if (size > actual_half_size) {

      //If allocation fails on the left, try allocating on the right side
      if ((array[m2a(left)] & ADDRESS_LOCATION) != 0 || *(short *)&array[m2a(left)] < actual_total_size){
        return NULL; // Return NULL if space is not available
      }
  
      //Mark the entire space as allocated
      *(short *)&array[m2a(left)] = actual_total_size | ADDRESS_LOCATION; 

      //Compute the heap address and return it
      return (void *)(heap_top + (left - mcb_top) * CHUNK_SIZE); 

    }else{
      //Allocate memory on the left side recursively
      heap_location = _ralloc(size, left, mid - mcb_ent_sz); 

      // If allocation succeeds
      if (heap_location != NULL) {

        // Check if the midpoint metadata is free
        if ((array[m2a(mid)] & ADDRESS_LOCATION) == 0){
          *(short *)&array[m2a(mid)] = actual_half_size; // Set metadata for the left half
        }

        //Return allocated heap address
        return heap_location;
      }

      //Allocate on the right side
      return _ralloc(size, mid, right); 
    }
    
  return NULL; // Return NULL if no allocation is possible
}


/*
 * Initializes MCB entries. In step 2's assembly coding, this routine must
 * be called from Reset_Handler in startup_TM4C129.s before you invoke
 * driver.c's main( ).
 */
void _kinit( ) {
  // Zeroing the heap space: no need to implement in step 2's assembly code.
  for ( int i = 0x20001000; i < 0x20005000; i++ )
    array[ m2a( i ) ] = 0;

  // Initializing MCB: you need to implement in step 2's assembly code.
  *(short *)&array[ m2a( mcb_top ) ] = max_size;
    
  for ( int i = 0x20006804; i < 0x20006C00; i += 2 ) {
    array[ m2a( i ) ] = 0;
    array[ m2a( i + 1) ] = 0;
  }
}

/*
 * Step 2 should call _kalloc from SVC_Handler.
 *
 * @param  the size of a requested memory space
 * @return a pointer to the allocated space
 */
void *_kalloc( int size ) {
  void *heap_addr = _ralloc((size < MIN_CHUNK_SIZE) ? MIN_CHUNK_SIZE : size, mcb_top, mcb_bot);
  if (heap_addr == NULL) {

    return NULL; // Return NULL if allocation failed
  }
  return heap_addr;
}

/*
 * Step 2 should call _kfree from SVC_Handler.
 *
 * @param  a pointer to the memory space to be deallocated.
 * @return the address of this deallocated space.
 */
void *_kfree(void *ptr) {
  int addr = (int)ptr;

  if (addr < heap_top || addr > heap_bot){
    return NULL;
  }
  
  // compute the mcb address corresponding to the addr to be deleted
  int mcb_addr =  mcb_top + (addr - heap_top) / CHUNK_SIZE;
  
  if (_rfree( mcb_addr ) == 0){
    return NULL;
  }else{
    return ptr;
  }
}

/*
 * _malloc should be implemented in stdlib.s in step 2.
 * _kalloc must be invoked through SVC in step 2.
 *
 * @param  the size of a requested memory space
 * @return a pointer to the allocated space
 */
void *_malloc( int size ) {
  static int init = 0;
  if ( init == 0 ) {
    init = 1;
    _kinit( ); // In step 2, you will call _kinit from Reset_Handler 
  }
  return _kalloc(size);
}

/*
 * _free should be implemented in stdlib.s in step 2.
 * _kfree must be invoked through SVC in step 2.
 *
 * @param  a pointer to the memory space to be deallocated.
 * @return the address of this deallocated space.
 */
void *_free( void *ptr ) {
  return _kfree( ptr );
}

/*
 * _rfree is _kfree's helper function that is recursively called to 
 * deallocate a space, using the buddy memory allocation algorithm.
 * Implement it by yourself in step 1
 * 
 * @param mcb_addr that corresponds to a SRAM space to deallocate
 * @return the same as the mcb_addr argument in success, otherwise 0.
 * 
*/

/*
 * Helper functions for merging blocks and clearing MCB entries.
 */
void merge_blocks_mcb_bot(int mcb_addr, int block_size, int actual_size) {
  *(short *)&array[m2a(mcb_addr + block_size)] = 0;// Clear the current MCB
  actual_size = actual_size * 2;
  *(short *)&array[m2a(mcb_addr)] = actual_size; // Merge with the buddy
}

void merge_blocks_mcb_top(int mcb_addr, int block_size, int actual_size) {
  *(short *)&array[m2a(mcb_addr)] = 0; // Clear the current MCB
  actual_size = actual_size * 2;
  *(short *)&array[m2a( mcb_addr - block_size)] = actual_size; // Merge with the buddy
}

short subtract_buddy_contents(int mcb_addr, int block_size){
  return *(short *)&array[m2a(mcb_addr - block_size)];
}

short add_buddy_contents(int mcb_addr, int block_size){
  return *(short *)&array[m2a(mcb_addr + block_size)];
}

int _rfree(int mcb_addr) {
  int block_offset = (mcb_addr - mcb_top); // Calculate the offset of the block address from the top of memory
  short block_contents = *(short *)&array[m2a(mcb_addr)]; // Get the MCB contents at the given address
  int block_size = (block_contents /= CHUNK_SIZE); // Determine the size of the memory chunk
  int actual_size = (block_contents *= CHUNK_SIZE); // Calculate the actual size of the memory block
  short contents = 0;

  // Update MCB contents to clear the used bit
  *(short *)&array[m2a(mcb_addr)] = block_contents; 

  // Check if the block is aligned and can be merged with its buddy
  if ((block_offset / block_size) % 2 != 0) {
    if (mcb_addr - block_size < mcb_top) {
      return 0; // Return 0 if the buddy is below the top of memory
    }else{
      contents = subtract_buddy_contents(mcb_addr, block_size);
      if ((contents & BIT_CLEAR_MASK) == 0){
        contents = (contents / MIN_CHUNK_SIZE) * MIN_CHUNK_SIZE; // Clear lower bits
        if (contents == actual_size) {
          merge_blocks_mcb_top(mcb_addr, block_size, actual_size);  
          return _rfree(mcb_addr - block_size); // Recursively call _rfree with the buddy's address
        }
      }
    }
  } else {
    if (mcb_addr + block_size >= mcb_bot) {
      return 0; // Return 0 if the buddy is beyond the bottom of memory
    }else{
      contents = add_buddy_contents(mcb_addr, block_size);
      if ((contents & BIT_CLEAR_MASK) == 0) {
        contents = (contents / MIN_CHUNK_SIZE) * MIN_CHUNK_SIZE; // Clear lower bits
        if (contents == actual_size) {
          merge_blocks_mcb_bot(mcb_addr, block_size, actual_size); 
          return _rfree(mcb_addr); // Recursively call _rfree with the current address
        }
      }
    }
  }
  return mcb_addr; // Return the block address
}

  