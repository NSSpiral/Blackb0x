#ifndef PWNUTIL_H
#define PWNUTIL_H

#include "plist.h"
#include "outputstate.h"
#include "hfsplus.h"

typedef int (*PatchFunction)(AbstractFile* file);

#ifdef __cplusplus
extern "C" {
#endif
	int patch(AbstractFile* in, AbstractFile* out, AbstractFile* patch);
	Dictionary* parseIPSW(const char* inputIPSW, const char* bundleRoot, char** bundlePath, OutputState** state);
	Dictionary* parseIPSW2(const char* inputIPSW, const char* bundleRoot, char** bundlePath, OutputState** state, int useMemory);
	int doPatch(StringValue* patchValue, StringValue* fileValue, const char* bundlePath, OutputState** state, unsigned int* key, unsigned int* iv, int useMemory, int isPlain);
	void doPatchInPlace(Volume* volume, const char* filePath, const char* patchPath);
	void doPatchInPlaceMemoryPatch(Volume* volume, const char* filePath, void** patch, size_t* patchSize);
	void fixupBootNeuterArgs(Volume* volume, char unlockBaseband, char selfDestruct, char use39, char use46);
	void createRestoreOptions(Volume* volume, int SystemPartitionSize, int UpdateBaseband);

	int patchSigCheck(AbstractFile* file);
	int patchKernel(AbstractFile* file);
	int patchDeviceTree(AbstractFile* file);
#ifdef __cplusplus
}
#endif

#endif
