#include <stdio.h>
#include <stdlib.h>

#pragma pack(push, 1)
typedef struct{
 	unsigned short type;
	unsigned long  size;
	unsigned short reserved1;
	unsigned short reserved2;
	unsigned long  offBits;
	unsigned long  bitSize;
	long  width;
	long  height;
	short planes;
	short bitPerPixel;
	unsigned long  compression;
	unsigned long  sizeImage;
	long xPelsPerMeter;
	long yPelsPerMeter;
	unsigned long  biClrUsed;
	unsigned long  biClrImportant;
	unsigned long  RGBQuad_0;
	unsigned long  RGBQuad_1;   
} bmpHeaderInfo;
#pragma pack(pop)

unsigned char *processImage(char* filePath);
extern void decode_ean8(unsigned char *out, void *img, int bytesPerBar);


int main (int argc, char* argv[]) {
    11asdasdasdasd2222dasdsadasdasdasd222
	if (argc != 2){
        printf("Please input only BMP file path of EAN8 barcode.\n");
    }
    char* filePath = argv[1];

    // Read and validate BMP file
    FILE *img;
    bmpHeaderInfo bmpHead;
    img = fopen(filePath, "rb");
    if (!img){
        printf("File with this path doesn't exist!\n");
        return 1;

    }

    fread((void *) &bmpHead, sizeof(bmpHeaderInfo), 1, img);

    // Read and validate BMP width
    int imageWidth = bmpHead.width;                                         
    if(imageWidth < 67 || imageWidth%67 != 0){
        printf("Image invalid.\n");
        return 1;
    }

    // Read and validate BMP width
    int imageHeight = bmpHead.height;
    if(imageHeight <= 0){
        return 1;
    }

    int barWidth = imageWidth/67;
    unsigned long imageDataSize = (((imageWidth + 31) >> 5) << 2) * 8;
    unsigned char *data = (unsigned char*) malloc(imageDataSize);
    fread(data, sizeof(unsigned char), imageDataSize, img);

    unsigned char* buf = malloc(sizeof(unsigned char)*9);
    decode_ean8(buf, data, barWidth);

    printf("\n================= EAN8 Decoder ===================\n");
    printf("\n\tDetails about image:\n");
    printf("\tImage width:\t\t%d\n", imageWidth);
    printf("\tImage height:\t\t%d\n", imageHeight);
    printf("\tBit per pixel:\t\t%d\n", bmpHead.bitPerPixel);
    printf("\tBar width (bytes): \t%d\n", barWidth);
    printf("\n==================================================\n");
    printf("\tDecoded EAN8 code: \t");
    for(int i=0; i < 8; i++){
        printf("%d", *buf);        
        buf++;
    }
    printf("\n==================================================\n");
    fclose(img);
    return 0;
}
