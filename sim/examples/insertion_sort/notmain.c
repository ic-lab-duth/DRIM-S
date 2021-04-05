// C program for insertion sort
#define DATA_SIZE 100

int array[DATA_SIZE] =
{
    41, 454, 833, 335, 564,   1, 187, 989, 749, 365, 350, 572, 132,  64, 949, 153, 584, 216, 805, 140,
    621, 210,   6, 572, 931, 339, 890, 593, 392, 898, 694, 228, 961,  12, 110, 883, 116, 750, 296, 646,
    426, 500, 314, 436, 659, 701, 774, 812, 319, 981, 678, 150, 875, 696, 376, 564, 474, 272, 938, 258,
    539, 647, 569, 509, 203,  88, 280, 703, 759, 669, 606, 375, 511, 551, 657, 936, 195, 592,  81, 569,
    267, 952, 229, 800, 337, 584, 944, 643, 902, 368, 241, 489, 913, 328, 826, 313, 933, 592, 985, 388
};

/* Function to sort an array using insertion sort*/
void insertionSort(int arr[], int n)
{
    int i, key, j;
    for (i = 1; i < n; i++)
    {
        key = arr[i];
        j = i - 1;

        /* Move elements of arr[0..i-1], that are
           greater than key, to one position ahead
           of their current position */
        while (j >= 0 && arr[j] > key)
        {
            arr[j + 1] = arr[j];
            j = j - 1;
        }
        arr[j + 1] = key;
    }
}

void notmain() {

    int n = sizeof(array) / sizeof(array[0]);
    insertionSort(array, n);
}