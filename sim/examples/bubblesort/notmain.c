#define MAX 20

int list[MAX] = {1,8,4,6,0,3,5,2,7,9,11,14,13,16,15,17,24,65,87,34};

void bubbleSort() {
   int temp;
   int i,j;
	
   int swapped = 0;
   
   // loop through all numbers 
   for(i = 0; i < MAX-1; i++) { 
      swapped = 0;
		
      // loop through numbers falling ahead 
      for(j = 0; j < MAX-1-i; j++) {
         // check if next number is lesser than current no
         //   swap the numbers. 
         //  (Bubble up the highest number)			
         if(list[j] > list[j+1]) {
            temp = list[j];
            list[j] = list[j+1];
            list[j+1] = temp;
            swapped = 1;
         }
			
      }

      // if no number was swapped that means 
      //   array is sorted now, break the loop. 
      if(swapped==0) {
         break;
      }
   }
	
}

void notmain() {
   bubbleSort();
}