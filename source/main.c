#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "pxi.h"
#include "DrawCharacter.h"
#include "i2c.h"
#include "lodepng.h"
#include "images.h"

uint8_t *const top_screen = (uint8_t *)0x18300000;
uint8_t *const bottom_screen = (uint8_t *)0x18477000;

#define KEYS                        ((*(volatile uint16_t*)0x10146000) ^ 0xFFF)
#define KEY_A                       (1<<0)
#define KEY_B                       (1<<1)
#define KEY_SELECT                  (1<<2)
#define KEY_START                   (1<<3)
#define KEY_RIGHT                   (1<<4)
#define KEY_LEFT                    (1<<5)
#define KEY_UP                      (1<<6)
#define KEY_DOWN                    (1<<7)
#define KEY_R                       (1<<8)
#define KEY_L                       (1<<9)
#define KEY_X                       (1<<10)
#define KEY_Y                       (1<<11)

// From GodMode9
static inline void _rgb_swap(uint8_t *img, size_t sz) {
    for (size_t i = 0; i < sz; i += 3) {
        uint8_t c = img[i];
        img[i] = img[i + 2];
        img[i + 2] = c;
    }
}

static unsigned PNG_Decompress(const uint8_t *png, size_t png_len, uint32_t *w, uint32_t *h, uint8_t **img)
{
    uint32_t res;
    size_t w_, h_;

    res = lodepng_decode24(img, &w_, &h_, png, png_len);
    if (res) {
        if (*img) free(*img);
        return res;
    }
    _rgb_swap(*img, w_ * h_ * 3);
    if (w) *w = w_;
    if (h) *h = h_;

    return 0;
}

// From GodMode9 ui.c
static void DrawBitmap(u8* screen, int w, int h, u8* bitmap) {
    u8* bitmapPos = bitmap;
    for (int yy = 0; yy < h; yy++) {
        int yDisplacement = ((h - yy - 1) * BYTES_PER_PIXEL);
        u8* screenPos = screen + yDisplacement;
        for (int xx = 0; xx < w; xx++) {
            memcpy(screenPos, bitmapPos, BYTES_PER_PIXEL);
            bitmapPos += BYTES_PER_PIXEL;
            screenPos += BYTES_PER_PIXEL * h;
        }
    }
}

static void waitToExit() {
    while (!(KEYS & KEY_B));
    while (!I2C_writeReg(I2C_DEV_MCU, 0x20, 1));
    while (true);
}

void memset32(void *dest, u32 filler, u32 size)
{
    u32 *dest32 = (u32 *)dest;

    for(u32 i = 0; i < size / 4; i++)
        dest32[i] = filler;
}

int main(int argc, char** argv) {
    // From GodMode9 main.c
    PXI_Reset();
    I2C_init();

    // Wait for ARM11
    PXI_WaitRemote(PXI_READY);

    PXI_DoCMD(PXI_SCREENINIT, NULL, 0);
    I2C_writeReg(I2C_DEV_MCU, 0x22, 0x2A);
    // End from GodMode9

    uint32_t w = 0, h = 0;
    uint8_t *img;

    unsigned r = PNG_Decompress(fh161_top_png, fh161_top_png_len, &w, &h, &img);
    if (img && w == 400 && h == 240) {
        DrawBitmap(top_screen, 400, 240, img);
    } else {
        DrawStringF(top_screen, 10, 10, "%u %ux%u", r, w, h);
    }
    if (img) free(img);

#if 0
    r = PNG_Decompress(fh161_bot_png, fh161_bot_png_len, &w, &h, &img);
    if (img && w == 320 && h == 240) {
        DrawBitmap(bottom_screen, 320, 240, img);
    } else {
        DrawStringF(bottom_screen, 10, 10, "%u %ux%u", r, w, h);
    }
    if (img) free(img);
#endif

    waitToExit();
    return 0;
}
