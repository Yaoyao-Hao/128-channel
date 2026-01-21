#ifndef PTX30W_UCODE_H_
#define PTX30W_UCODE_H_

#include <stdint.h>
#include <stddef.h>

extern const char *ptx30w_uCode_SRC;
extern const uint16_t ptx30w_uCode_SRC_REV;
extern const char *ptx30w_uCode_ASM;
extern const uint16_t ptx30w_uCode_ASM_REV;

#define SIZE_OF_UCODE_SECTION (0x07CA) // 1994
extern const uint16_t ptx30w_uCode[SIZE_OF_UCODE_SECTION];

#endif