void notmain(void) {
    
	int pixel, temp, new_pixel, sum;
	//Initialize the Pointers for the Memory Accesses
	short variable_1;
	short *image_addr = &variable_1;

	unsigned int variable_2;
	unsigned int *frame_buffer = &variable_2;
	//Base Addresses of the Picture/Frame Buffer in Memory
	unsigned int initial_frame_addr = 0xffff0000;
	unsigned int initial_image_addr = 0xc0;
    int i;
    

	//Start the Low Pas Filtering
    for (i = 160; i < 19200-160; ++i)
    {
        sum = 0;
        //Read Adjoining Pixels        
        image_addr = (void *)(initial_image_addr+i-1);
        new_pixel  = *image_addr;
        new_pixel  = new_pixel & 0x1f;
        sum = sum + new_pixel;
        image_addr = (void *)(initial_image_addr+i+1);
        new_pixel  = *image_addr;
        new_pixel  = new_pixel & 0x1f;
        sum = sum + new_pixel;
        image_addr = (void *)(initial_image_addr+i-160);
        new_pixel  = *image_addr;
        new_pixel  = new_pixel & 0x1f;
        sum = sum + new_pixel;
        image_addr = (void *)(initial_image_addr+i+160);
        new_pixel  = *image_addr;
        new_pixel  = new_pixel & 0x1f;
        sum = sum + new_pixel;
        //Divide by 4
        sum = sum >> 2;
        //Read Center Pixel
        image_addr = (void *)(initial_image_addr+i);
        new_pixel  = *image_addr;
        new_pixel  = new_pixel & 0x1f;
        sum = sum + new_pixel;
        //Divide by 2
        pixel = sum >> 1;

        //Process The Colors for the Output
        pixel = pixel & 0x1f; //Keep only five lower bits (red channel) (0x1f==31)
        temp  = pixel << 5;
        pixel = pixel | temp;//Copy the Same five bits to the next 5 bits (green channel)
        temp  = temp << 5;
        pixel = pixel | temp;//Copy the same five bits to the next 5 bits (blue channel)
        //Print Pixel to Screen
        frame_buffer  = (void *)(initial_frame_addr+i);
        *frame_buffer = pixel;
    }
}


