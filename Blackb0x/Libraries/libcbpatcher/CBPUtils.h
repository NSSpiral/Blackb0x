//
//  CBPUtils.h
//  CBPatcher
//
//  Created by JonathanSeals on 11/18/18.
//  Copyright © 2018 JonathanSeals. All rights reserved.
//

#ifndef CBPUtils_h
#define CBPUtils_h

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Get a buffer from a file name. Returns -1 on failure, 0 on success */
int openFile(char *fileName, size_t *fileSize, void **outBuf);

#endif /* CBPUtils_h */
