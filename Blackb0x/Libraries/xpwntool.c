//
//  xpwntool.c
//  Blackb0x
//
#include <stdio.h>
#include <string.h>

#include <libxpwntool/libxpwn.h>
#include <libxpwntool/nor_files.h>

#define BUFFERSIZE (1024*1024)

void decrypt(char *input_path, char *ouput_path, char *ip_key, char *ip_iv, char *decrypt, char *template_path);


void decrypt(char *input_path, char *ouput_path, char *ip_key, char *ip_iv, char *decrypt, char *template_path) {
    
    printf("input_path %s", input_path);
  char* inData;
    size_t inDataSize;
    init_libxpwn();
    AbstractFile* template = NULL;
    AbstractFile* certificate = NULL;
    unsigned int* key = NULL;
    unsigned int* iv = NULL;
    int hasKey = FALSE;
    int hasIV = FALSE;
    int doDecrypt = FALSE;

    if(strcmp(decrypt, "TRUE") == 0) {
        doDecrypt = TRUE;
        template = createAbstractFileFromFile(fopen(input_path, "rb"));
    }

    if (template_path && template_path[0]) {
        template = createAbstractFileFromFile(fopen(template_path, "rb"));
    }

    if (ip_key && ip_key[0]) {
        hasKey = TRUE;
        hasIV = TRUE;
    }
    
    printf("decrypt %d \n", doDecrypt);

    if(hasKey == TRUE) {
    
    size_t bytes;
    hexToInts(ip_key, &key, &bytes);
    }
    if(hasIV == TRUE) {
    size_t bytes;
    hexToInts(ip_iv, &iv, &bytes);
    }
    AbstractFile* inFile;
    if(doDecrypt) {
        if(hasKey) {
            inFile = openAbstractFile3(createAbstractFileFromFile(fopen(input_path, "rb")), key, iv, 0);
        } else {
            inFile = openAbstractFile3(createAbstractFileFromFile(fopen(input_path, "rb")), NULL, NULL, 0);
        }
    } else {
        if(hasKey) {
            inFile = openAbstractFile2(createAbstractFileFromFile(fopen(input_path, "rb")), key, iv);
        } else {
            inFile = openAbstractFile(createAbstractFileFromFile(fopen(input_path, "rb")));
        }
    }
    if(!inFile) {
        fprintf(stderr, "error: cannot open infile\n");
    }

    AbstractFile* outFile = createAbstractFileFromFile(fopen(ouput_path, "wb"));
    if(!outFile) {
        fprintf(stderr, "error: cannot open outfile\n");
    }


    AbstractFile* newFile;

    if(template) {
        if(hasKey && !doDecrypt) {
            newFile = duplicateAbstractFile2(template, outFile, key, iv, certificate);
        } else {
            newFile = duplicateAbstractFile2(template, outFile, NULL, NULL, certificate);
        }
        if(!newFile) {
            fprintf(stderr, "error: cannot duplicate file from provided template\n");
        }
    } else {
        newFile = outFile;
    }

    if(hasKey && !doDecrypt) {
        if(newFile->type == AbstractFileTypeImg3) {
            AbstractFile2* abstractFile2 = (AbstractFile2*) newFile;
            abstractFile2->setKey(abstractFile2, key, iv);
        }
    }

    inDataSize = (size_t) inFile->getLength(inFile);
    inData = (char*) malloc(inDataSize);
    inFile->read(inFile, inData, inDataSize);
    inFile->close(inFile);

    newFile->write(newFile, inData, inDataSize);
    newFile->close(newFile);

    free(inData);

    if(key)
        free(key);

    if(iv)
        free(iv);

}
