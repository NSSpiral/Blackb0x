//
//  CBPatcher.c
//  CBPatcher
//
//  Created by JonathanSeals on 11/18/18.
//  Copyright © 2018 JonathanSeals. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libcbpatcher/CBPUtils.h>
#include <libcbpatcher/CBPatch.h>


int patch_kernel(char* infile, char* outfile, char* version);

int patch_kernel(char* infile, char* outfile, char* version) {
   
    int nukesb = 1;
   
    char *fileName = infile;
   
    void *fileBuf = 0;
   
    size_t fileLen = 0;
   
    int ret = openFile(fileName, &fileLen, &fileBuf);
   
    if (ret) {
        printf("Failed to open %s\n", fileName);
        return -1;
    }
   
    char *versionNum = version;
   
    ret = kernPat(fileBuf, fileLen, versionNum, nukesb);
   
    if (ret) {
        printf("Failed to patch kernel\n");
        free(fileBuf);
        return -1;
    }
   
    printf("Kernel patched successfully\n");
   
    FILE *outFile = fopen(outfile, "w");
    fwrite(fileBuf, fileLen, 1, outFile);
    fflush(outFile);
    fclose(outFile);
   
    free(fileBuf);
   
    return 0;
}

