//
//  libiboot32patcher.h
//  Blackb0x
//
//  Created by spiral on 12/10/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif

#ifndef libiboot32patcher_h
#define libiboot32patcher_h


int iBootPatcher(char *infile, char *outfile, char *args, char *RSA, char *debug, char *ticket, char *kaslr);

#endif /* libiboot32patcher_h */

#ifdef __cplusplus
}
#endif
