#ifndef Graphic_h_
#define Graphic_h_

#define RGB(r, g, b) ((((r) << 11) | ((g) << 5) | (b)) & 0xffff)
											/* RGB로부터 색 코드를 얻는 매크로 */

#define RGB_MAX 0x1f						/* RED와 BLUE의 최대값 */
#define GREEN_MAX 0x3f						/* GREEN의 최대값 */

/* RGB 밝기 레벨 */
#define RGB_LEVEL1 (RGB_MAX*4/4)
#define RGB_LEVEL2 (RGB_MAX*3/4)
#define RGB_LEVEL3 (RGB_MAX*2/4)
#define RGB_LEVEL4 (RGB_MAX*1/4)

/* GREEN 밝기 레벨 */
#define GREEN_LEVEL1 (GREEN_MAX*4/4)
#define GREEN_LEVEL2 (GREEN_MAX*3/4)
#define GREEN_LEVEL3 (GREEN_MAX*2/4)
#define GREEN_LEVEL4 (GREEN_MAX*1/4)

/* 빨강(RED) 계열 (SCARLET = 진홍색) */
#define RED					RGB(RGB_LEVEL1,0,0)
#define BRIGHT_SCARLET		RGB(RGB_LEVEL2,0,0)
#define SCARLET				RGB(RGB_LEVEL3,0,0)
#define DARK_SCARLET		RGB(RGB_LEVEL4,0,0)

/* 초록색(LIGNTGREEN) 계열 (진한건 그냥 GREEN(녹색)) */
#define LIGHTGREEN			RGB(0,GREEN_LEVEL1,0)
#define BRIGHT_GRREN		RGB(0,GREEN_LEVEL2,0)
#define GREEN				RGB(0,GREEN_LEVEL3,0)
#define DARK_GREEN			RGB(0,GREEN_LEVEL4,0)

/* 파란색(BLUE) 계열 (NAVY = 남색) */
#define BLUE				RGB(0,0,RGB_LEVEL1)
#define BRIGHT_NAVY			RGB(0,0,RGB_LEVEL2)
#define NAVY				RGB(0,0,RGB_LEVEL3)
#define DARK_NAVY			RGB(0,0,RGB_LEVEL4)

/* 노란색(YELLOW) 계열 (DEEPYELLOW = 진한 노랑색) */
#define YELLOW				RGB(RGB_LEVEL1,GREEN_LEVEL1,0)
#define DARK_DEEPYELLOW		RGB(RGB_LEVEL2,GREEN_LEVEL2,0)
#define DEEPYELLOW			RGB(RGB_LEVEL3,GREEN_LEVEL3,0)
#define BRIGHT_DEEPYELLOW	RGB(RGB_LEVEL4,GREEN_LEVEL4,0)

/* 마젠타(밝은 자주색:MAGENTA) 계열 (PLUM = 자주색) */
#define MAGENTA				RGB(RGB_LEVEL1,0,RGB_LEVEL1)
#define DARK_PLUM			RGB(RGB_LEVEL2,0,RGB_LEVEL2)
#define PLUM				RGB(RGB_LEVEL3,0,RGB_LEVEL3)
#define BRIGHT_PLUM			RGB(RGB_LEVEL4,0,RGB_LEVEL4)

/* 시안(밝은 청록색) 계열 (BLUEGREEN = 청록색) */
#define CYAN				RGB(0,GREEN_LEVEL1,RGB_LEVEL1)
#define DARK_BLUEGREEN		RGB(0,GREEN_LEVEL2,RGB_LEVEL2)
#define BLUEGREEN			RGB(0,GREEN_LEVEL3,RGB_LEVEL3)
#define BRIGHT_BLUEGREEN	RGB(0,GREEN_LEVEL4,RGB_LEVEL4)

/* 흰색(WHITE) 계열 (GRAY = 회색) */
#define WHITE				RGB(RGB_LEVEL1,GREEN_LEVEL1,RGB_LEVEL1)
#define BRIGHT_GRAY			RGB(RGB_LEVEL2,GREEN_LEVEL2,RGB_LEVEL2)
#define GRAY				RGB(RGB_LEVEL3,GREEN_LEVEL3,RGB_LEVEL3)
#define DARK_GRAY			RGB(RGB_LEVEL4,GREEN_LEVEL4,RGB_LEVEL4)

#define BLACK				RGB(0,0,0)

/* Clubcos0이 사용하는 색상들 */
#define BACK_COLOR DARK_BLUEGREEN

/* 색상을 나타내는 타입 (16bit = WORD) */
typedef uint16_t Color;

/* BootInfo */
typedef struct tagBootInfo
{
	uint32_t ReadCylinders;						/* READ_CYLS : 읽어들인 실린더 수 */
	uint32_t ScreenX;							/* SCREEN_X : 화면의 X좌표 크기 */
	uint32_t ScreenY;							/* SCREEN_Y : 화면의 X좌표 크기 */
	Color *VideoMemory;							/* VIDEO_MEMORY : 비디오 메모리의 포인터 */
} BootInfo;

static inline BootInfo *GetBootInfo() { return (BootInfo *)0x268000; }

#define PRINT_XY(X, Y) ((X) + ((Y) * GetBootInfo()->ScreenX))

void DrawBoxFill(int x1, int y1, int x2, int y2, Color color);

void DrawFont(const unsigned char *font, int x, int y, Color c);
void DrawString(int x, int y, Color c, const char *str);
void DrawStringFormat(int x, int y, Color c, const char *format, ...);

// inline function
static inline void DrawPixel(int x, int y, Color color)
{
	GetBootInfo()->VideoMemory[PRINT_XY(x, y)] = color;
}

static inline void DrawBox(int x1, int y1, int x2, int y2, Color color)
{
	DrawBoxFill(x1, y1, x2, y1, color);
	DrawBoxFill(x2, y1, x2, y2, color);
	DrawBoxFill(x1, y2, x2, y2, color);
	DrawBoxFill(x1, y1, x1, y2, color);
}


extern unsigned char g_vucEnglishFont[];

#endif // Graphic_h_
