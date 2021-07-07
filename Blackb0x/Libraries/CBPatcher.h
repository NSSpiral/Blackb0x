//
//  CBPatcher.h
//  Blackb0x
//
//  Created by spiral on 12/10/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif

#ifndef CBPatcher_h
#define CBPatcher_h

int patch_kernel(char* infile, char* outfile, char* version);

#endif /* CBPatcher_h */

#ifdef __cplusplus
}
#endif
