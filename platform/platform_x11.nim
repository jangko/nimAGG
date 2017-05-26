#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/keysym.h>
#include "agg_basics.h"
#include "util/agg_color_conv_rgb8.h"
#include "platform/agg_platform_support.h"

type
  PlatformSpecific[T] = object
    mUpdateFlag: bool
    mResizeFlag: bool
    mInitialized: bool
    mSwStart: Clock
#[
{
public:
    platforself.mSpecific(pix_format_e format, bool flipY);
    ~platforself.mSpecific();
    
    proc caption(const char* capt);
    proc put_image(const rendering_buffer* src);
   
    pix_format_e         mFormat;
    pix_format_e         mSysFormat;
    int                  mByteOrder;
    bool                 mFlipY;
    unsigned             mBpp;
    unsigned             mSysBpp;
    Display*             mDisplay;
    int                  mSceen;
    int                  mDepth;
    Visual*              mVisual;
    Window               mWindow;
    GC                   mGC;
    XImage*              mXimgWindow;
    XSetWindowAttributes mWindowAttributes;
    Atom                 mCloseAtom;
    unsigned char*       mBufWindow;
    unsigned char*       mBufImg[platform_support::max_images];
    unsigned             mKeyMap[256];
   
    //bool self.mWaitMode;
    
};




platforself.mSpecific::platforself.mSpecific(pix_format_e format, bool flipY) :
    self.mFormat(format),
    self.mSysFormat(pix_format_undefined),
    self.mByteOrder(LSBFirst),
    self.mFlipY(flipY),
    self.mBpp(0),
    self.mSysBpp(0),
    self.mDisplay(0),
    self.mSceen(0),
    self.mDepth(0),
    self.mVisual(0),
    self.mWindow(0),
    self.mGC(0),
    self.mXimgWindow(0),
    self.mCloseAtom(0),

    self.mBufWindow(0),
    
    self.mUpdateFlag(true), 
    self.mResizeFlag(true),
    self.mInitialized(false)
    //self.mWaitMode(true)
{
    memset(self.mBufImg, 0, sizeof(self.mBufImg));

    unsigned i;
    for(i = 0; i < 256; i++)
    {
        self.mKeyMap[i] = i;
    }

    self.mKeyMap[XK_Pause and 0xFF] = key_pause;
    self.mKeyMap[XK_Clear and 0xFF] = key_clear;

    self.mKeyMap[XK_KP_0 and 0xFF] = key_kp0;
    self.mKeyMap[XK_KP_1 and 0xFF] = key_kp1;
    self.mKeyMap[XK_KP_2 and 0xFF] = key_kp2;
    self.mKeyMap[XK_KP_3 and 0xFF] = key_kp3;
    self.mKeyMap[XK_KP_4 and 0xFF] = key_kp4;
    self.mKeyMap[XK_KP_5 and 0xFF] = key_kp5;
    self.mKeyMap[XK_KP_6 and 0xFF] = key_kp6;
    self.mKeyMap[XK_KP_7 and 0xFF] = key_kp7;
    self.mKeyMap[XK_KP_8 and 0xFF] = key_kp8;
    self.mKeyMap[XK_KP_9 and 0xFF] = key_kp9;

    self.mKeyMap[XK_KP_Insert and 0xFF]    = key_kp0;
    self.mKeyMap[XK_KP_End and 0xFF]       = key_kp1;   
    self.mKeyMap[XK_KP_Down and 0xFF]      = key_kp2;
    self.mKeyMap[XK_KP_Page_Down and 0xFF] = key_kp3;
    self.mKeyMap[XK_KP_Left and 0xFF]      = key_kp4;
    self.mKeyMap[XK_KP_Begin and 0xFF]     = key_kp5;
    self.mKeyMap[XK_KP_Right and 0xFF]     = key_kp6;
    self.mKeyMap[XK_KP_Home and 0xFF]      = key_kp7;
    self.mKeyMap[XK_KP_Up and 0xFF]        = key_kp8;
    self.mKeyMap[XK_KP_Page_Up and 0xFF]   = key_kp9;
    self.mKeyMap[XK_KP_Delete and 0xFF]    = key_kp_period;
    self.mKeyMap[XK_KP_Decimal and 0xFF]   = key_kp_period;
    self.mKeyMap[XK_KP_Divide and 0xFF]    = key_kp_divide;
    self.mKeyMap[XK_KP_Multiply and 0xFF]  = key_kp_multiply;
    self.mKeyMap[XK_KP_Subtract and 0xFF]  = key_kp_minus;
    self.mKeyMap[XK_KP_Add and 0xFF]       = key_kp_plus;
    self.mKeyMap[XK_KP_Enter and 0xFF]     = key_kp_enter;
    self.mKeyMap[XK_KP_Equal and 0xFF]     = key_kp_equals;

    self.mKeyMap[XK_Up and 0xFF]           = key_up;
    self.mKeyMap[XK_Down and 0xFF]         = key_down;
    self.mKeyMap[XK_Right and 0xFF]        = key_right;
    self.mKeyMap[XK_Left and 0xFF]         = key_left;
    self.mKeyMap[XK_Insert and 0xFF]       = key_insert;
    self.mKeyMap[XK_Home and 0xFF]         = key_delete;
    self.mKeyMap[XK_End and 0xFF]          = key_end;
    self.mKeyMap[XK_Page_Up and 0xFF]      = key_page_up;
    self.mKeyMap[XK_Page_Down and 0xFF]    = key_page_down;

    self.mKeyMap[XK_F1 and 0xFF]           = key_f1;
    self.mKeyMap[XK_F2 and 0xFF]           = key_f2;
    self.mKeyMap[XK_F3 and 0xFF]           = key_f3;
    self.mKeyMap[XK_F4 and 0xFF]           = key_f4;
    self.mKeyMap[XK_F5 and 0xFF]           = key_f5;
    self.mKeyMap[XK_F6 and 0xFF]           = key_f6;
    self.mKeyMap[XK_F7 and 0xFF]           = key_f7;
    self.mKeyMap[XK_F8 and 0xFF]           = key_f8;
    self.mKeyMap[XK_F9 and 0xFF]           = key_f9;
    self.mKeyMap[XK_F10 and 0xFF]          = key_f10;
    self.mKeyMap[XK_F11 and 0xFF]          = key_f11;
    self.mKeyMap[XK_F12 and 0xFF]          = key_f12;
    self.mKeyMap[XK_F13 and 0xFF]          = key_f13;
    self.mKeyMap[XK_F14 and 0xFF]          = key_f14;
    self.mKeyMap[XK_F15 and 0xFF]          = key_f15;

    self.mKeyMap[XK_Num_Lock and 0xFF]     = key_numlock;
    self.mKeyMap[XK_Caps_Lock and 0xFF]    = key_capslock;
    self.mKeyMap[XK_Scroll_Lock and 0xFF]  = key_scrollock;

    switch(self.mFormat)
    {
    default: break;
    case pix_format_gray8:
        self.mBpp = 8;
        break;

    case pix_format_rgb565:
    case pix_format_rgb555:
        self.mBpp = 16;
        break;

    case pix_format_rgb24:
    case pix_format_bgr24:
        self.mBpp = 24;
        break;

    case pix_format_bgra32:
    case pix_format_abgr32:
    case pix_format_argb32:
    case pix_format_rgba32:
        self.mBpp = 32;
        break;
    }
    self.mSwStart = clock();
}


platforself.mSpecific::~platforself.mSpecific()
{
}


proc platforself.mSpecific::caption(const char* capt)
{
    //XTextProperty tp;
    //tp.value = (unsigned char *)capt;
    //tp.encoding = XA_WM_NAME;
    //tp.format = 8;
    //tp.nitems = strlen(capt);
    //XSetWMName(self.mDisplay, self.mWindow, &tp);
    //XStoreName(self.mDisplay, self.mWindow, capt);
    //XSetIconName(self.mDisplay, self.mWindow, capt);
    //XSetWMIconName(self.mDisplay, self.mWindow, &tp);
    // Fixed by Enno Fennema
    XStoreName(self.mDisplay, self.mWindow, capt);
    XSetIconName(self.mDisplay, self.mWindow, capt);
}



proc platforself.mSpecific::put_image(const rendering_buffer* src)
{    
    if(self.mXimgWindow == 0) return;
    self.mXimgWindow.data = (char*)self.mBufWindow;
    
    if(self.mFormat == self.mSysFormat)
    {
        XPutImage(self.mDisplay, 
                  self.mWindow, 
                  self.mGC, 
                  self.mXimgWindow, 
                  0, 0, 0, 0,
                  src.width(), 
                  src.height());
    }
    else
    {
        int row_len = src.width() * self.mSysBpp / 8;
        unsigned char* buf_tmp = 
            new unsigned char[row_len * src.height()];
        
        rendering_buffer rbuf_tmp;
        rbuf_tmp.attach(buf_tmp, 
                        src.width(), 
                        src.height(), 
                        self.mFlipY ? -row_len : row_len);

        switch(self.mSysFormat)            
        {
            default: break;
            case pix_format_rgb555:
                switch(self.mFormat)
                {
                    default: break;
                    case pix_format_rgb555: color_conv(&rbuf_tmp, src, color_conv_rgb555_to_rgb555()); break;
                    case pix_format_rgb565: color_conv(&rbuf_tmp, src, color_conv_rgb565_to_rgb555()); break;
                    case pix_format_rgb24:  color_conv(&rbuf_tmp, src, color_conv_rgb24_to_rgb555());  break;
                    case pix_format_bgr24:  color_conv(&rbuf_tmp, src, color_conv_bgr24_to_rgb555());  break;
                    case pix_format_rgba32: color_conv(&rbuf_tmp, src, color_conv_rgba32_to_rgb555()); break;
                    case pix_format_argb32: color_conv(&rbuf_tmp, src, color_conv_argb32_to_rgb555()); break;
                    case pix_format_bgra32: color_conv(&rbuf_tmp, src, color_conv_bgra32_to_rgb555()); break;
                    case pix_format_abgr32: color_conv(&rbuf_tmp, src, color_conv_abgr32_to_rgb555()); break;
                }
                break;
                
            case pix_format_rgb565:
                switch(self.mFormat)
                {
                    default: break;
                    case pix_format_rgb555: color_conv(&rbuf_tmp, src, color_conv_rgb555_to_rgb565()); break;
                    case pix_format_rgb565: color_conv(&rbuf_tmp, src, color_conv_rgb565_to_rgb565()); break;
                    case pix_format_rgb24:  color_conv(&rbuf_tmp, src, color_conv_rgb24_to_rgb565());  break;
                    case pix_format_bgr24:  color_conv(&rbuf_tmp, src, color_conv_bgr24_to_rgb565());  break;
                    case pix_format_rgba32: color_conv(&rbuf_tmp, src, color_conv_rgba32_to_rgb565()); break;
                    case pix_format_argb32: color_conv(&rbuf_tmp, src, color_conv_argb32_to_rgb565()); break;
                    case pix_format_bgra32: color_conv(&rbuf_tmp, src, color_conv_bgra32_to_rgb565()); break;
                    case pix_format_abgr32: color_conv(&rbuf_tmp, src, color_conv_abgr32_to_rgb565()); break;
                }
                break;
                
            case pix_format_rgba32:
                switch(self.mFormat)
                {
                    default: break;
                    case pix_format_rgb555: color_conv(&rbuf_tmp, src, color_conv_rgb555_to_rgba32()); break;
                    case pix_format_rgb565: color_conv(&rbuf_tmp, src, color_conv_rgb565_to_rgba32()); break;
                    case pix_format_rgb24:  color_conv(&rbuf_tmp, src, color_conv_rgb24_to_rgba32());  break;
                    case pix_format_bgr24:  color_conv(&rbuf_tmp, src, color_conv_bgr24_to_rgba32());  break;
                    case pix_format_rgba32: color_conv(&rbuf_tmp, src, color_conv_rgba32_to_rgba32()); break;
                    case pix_format_argb32: color_conv(&rbuf_tmp, src, color_conv_argb32_to_rgba32()); break;
                    case pix_format_bgra32: color_conv(&rbuf_tmp, src, color_conv_bgra32_to_rgba32()); break;
                    case pix_format_abgr32: color_conv(&rbuf_tmp, src, color_conv_abgr32_to_rgba32()); break;
                }
                break;
                
            case pix_format_abgr32:
                switch(self.mFormat)
                {
                    default: break;
                    case pix_format_rgb555: color_conv(&rbuf_tmp, src, color_conv_rgb555_to_abgr32()); break;
                    case pix_format_rgb565: color_conv(&rbuf_tmp, src, color_conv_rgb565_to_abgr32()); break;
                    case pix_format_rgb24:  color_conv(&rbuf_tmp, src, color_conv_rgb24_to_abgr32());  break;
                    case pix_format_bgr24:  color_conv(&rbuf_tmp, src, color_conv_bgr24_to_abgr32());  break;
                    case pix_format_abgr32: color_conv(&rbuf_tmp, src, color_conv_abgr32_to_abgr32()); break;
                    case pix_format_rgba32: color_conv(&rbuf_tmp, src, color_conv_rgba32_to_abgr32()); break;
                    case pix_format_argb32: color_conv(&rbuf_tmp, src, color_conv_argb32_to_abgr32()); break;
                    case pix_format_bgra32: color_conv(&rbuf_tmp, src, color_conv_bgra32_to_abgr32()); break;
                }
                break;
                
            case pix_format_argb32:
                switch(self.mFormat)
                {
                    default: break;
                    case pix_format_rgb555: color_conv(&rbuf_tmp, src, color_conv_rgb555_to_argb32()); break;
                    case pix_format_rgb565: color_conv(&rbuf_tmp, src, color_conv_rgb565_to_argb32()); break;
                    case pix_format_rgb24:  color_conv(&rbuf_tmp, src, color_conv_rgb24_to_argb32());  break;
                    case pix_format_bgr24:  color_conv(&rbuf_tmp, src, color_conv_bgr24_to_argb32());  break;
                    case pix_format_rgba32: color_conv(&rbuf_tmp, src, color_conv_rgba32_to_argb32()); break;
                    case pix_format_argb32: color_conv(&rbuf_tmp, src, color_conv_argb32_to_argb32()); break;
                    case pix_format_abgr32: color_conv(&rbuf_tmp, src, color_conv_abgr32_to_argb32()); break;
                    case pix_format_bgra32: color_conv(&rbuf_tmp, src, color_conv_bgra32_to_argb32()); break;
                }
                break;
                
            case pix_format_bgra32:
                switch(self.mFormat)
                {
                    default: break;
                    case pix_format_rgb555: color_conv(&rbuf_tmp, src, color_conv_rgb555_to_bgra32()); break;
                    case pix_format_rgb565: color_conv(&rbuf_tmp, src, color_conv_rgb565_to_bgra32()); break;
                    case pix_format_rgb24:  color_conv(&rbuf_tmp, src, color_conv_rgb24_to_bgra32());  break;
                    case pix_format_bgr24:  color_conv(&rbuf_tmp, src, color_conv_bgr24_to_bgra32());  break;
                    case pix_format_rgba32: color_conv(&rbuf_tmp, src, color_conv_rgba32_to_bgra32()); break;
                    case pix_format_argb32: color_conv(&rbuf_tmp, src, color_conv_argb32_to_bgra32()); break;
                    case pix_format_abgr32: color_conv(&rbuf_tmp, src, color_conv_abgr32_to_bgra32()); break;
                    case pix_format_bgra32: color_conv(&rbuf_tmp, src, color_conv_bgra32_to_bgra32()); break;
                }
                break;
        }
        
        self.mXimgWindow.data = (char*)buf_tmp;
        XPutImage(self.mDisplay, 
                  self.mWindow, 
                  self.mGC, 
                  self.mXimgWindow, 
                  0, 0, 0, 0,
                  src.width(), 
                  src.height());
        
        delete [] buf_tmp;
    }
}
]#


proc init[T,R](self: GenericPlatform[T,R], format: PixFormat, flipY: bool) =
  discard
#[    self.mSpecific(new platforself.mSpecific(format, flipY)),
    self.mFormat(format),
    self.mBpp(self.mSpecific.mBpp),
    self.mWindowFlags(0),
    self.mWaitMode(true),
    self.mFlipY(flipY),
    self.mInitialWidth(10),
    self.mInitialHeight(10)
    strcpy(m_caption, "AGG Application");]#

proc caption[T,R](self: GenericPlatform[T,R], cap: string) =
  discard
  #[strcpy(m_caption, cap);
    if(self.mSpecific.mInitialized)
    {
        self.mSpecific.caption(cap);
  ]#

#[
enum xevent_mask_e
{ 
    xevent_mask =
        PointerMotionMask|
        ButtonPressMask|
        ButtonReleaseMask|
        ExposureMask|
        KeyPressMask|
        StructureNotifyMask
};
]#


proc init*[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags, fileName: string): bool =
  self.mWindowFlags = flags
  result = true
  #[  
    self.mSpecific.mDisplay = XOpenDisplay(NULL);
    if(self.mSpecific.mDisplay == 0) 
    {
        fprintf(stderr, "Unable to open DISPLAY!\n");
        return false;
    }
    
    self.mSpecific.mSceen = XDefaultScreen(self.mSpecific.mDisplay);
    self.mSpecific.mDepth  = XDefaultDepth(self.mSpecific.mDisplay, 
                                         self.mSpecific.mSceen);
    self.mSpecific.mVisual = XDefaultVisual(self.mSpecific.mDisplay, 
                                          self.mSpecific.mSceen);
    unsigned long r_mask = self.mSpecific.mVisual.red_mask;
    unsigned long g_mask = self.mSpecific.mVisual.green_mask;
    unsigned long b_mask = self.mSpecific.mVisual.blue_mask;
 

    if(self.mSpecific.mDepth < 15 ||
       r_mask == 0 || g_mask == 0 || b_mask == 0)
    {
        fprintf(stderr,
               "There's no Visual compatible with minimal AGG requirements:\n"
               "At least 15-bit color depth and True- or DirectColor class.\n\n");
        XCloseDisplay(self.mSpecific.mDisplay);
        return false;
    }
    
    int t = 1;
    int hw_byte_order = LSBFirst;
    if(*(char*)&t == 0) hw_byte_order = MSBFirst;
    
    // Perceive SYS-format by mask
    switch(self.mSpecific.mDepth)
    {
        case 15:
            self.mSpecific.mSysBpp = 16;
            if(r_mask == 0x7C00 && g_mask == 0x3E0 && b_mask == 0x1F)
            {
                self.mSpecific.mSysFormat = pix_format_rgb555;
                self.mSpecific.mByteOrder = hw_byte_order;
            }
            break;
            
        case 16:
            self.mSpecific.mSysBpp = 16;
            if(r_mask == 0xF800 && g_mask == 0x7E0 && b_mask == 0x1F)
            {
                self.mSpecific.mSysFormat = pix_format_rgb565;
                self.mSpecific.mByteOrder = hw_byte_order;
            }
            break;
            
        case 24:
        case 32:
            self.mSpecific.mSysBpp = 32;
            if(g_mask == 0xFF00)
            {
                if(r_mask == 0xFF && b_mask == 0xFF0000)
                {
                    switch(self.mSpecific.mFormat)
                    {
                        case pix_format_rgba32:
                            self.mSpecific.mSysFormat = pix_format_rgba32;
                            self.mSpecific.mByteOrder = LSBFirst;
                            break;
                            
                        case pix_format_abgr32:
                            self.mSpecific.mSysFormat = pix_format_abgr32;
                            self.mSpecific.mByteOrder = MSBFirst;
                            break;

                        default:                            
                            self.mSpecific.mByteOrder = hw_byte_order;
                            self.mSpecific.mSysFormat = 
                                (hw_byte_order == LSBFirst) ?
                                pix_format_rgba32 :
                                pix_format_abgr32;
                            break;
                    }
                }
                
                if(r_mask == 0xFF0000 && b_mask == 0xFF)
                {
                    switch(self.mSpecific.mFormat)
                    {
                        case pix_format_argb32:
                            self.mSpecific.mSysFormat = pix_format_argb32;
                            self.mSpecific.mByteOrder = MSBFirst;
                            break;
                            
                        case pix_format_bgra32:
                            self.mSpecific.mSysFormat = pix_format_bgra32;
                            self.mSpecific.mByteOrder = LSBFirst;
                            break;

                        default:                            
                            self.mSpecific.mByteOrder = hw_byte_order;
                            self.mSpecific.mSysFormat = 
                                (hw_byte_order == MSBFirst) ?
                                pix_format_argb32 :
                                pix_format_bgra32;
                            break;
                    }
                }
            }
            break;
    }
    
    if(self.mSpecific.mSysFormat == pix_format_undefined)
    {
        fprintf(stderr,
               "RGB masks are not compatible with AGG pixel formats:\n"
               "R=%08x, R=%08x, B=%08x\n", r_mask, g_mask, b_mask);
        XCloseDisplay(self.mSpecific.mDisplay);
        return false;
    }
            
    
    
    memset(&self.mSpecific.mWindowAttributes, 
           0, 
           sizeof(self.mSpecific.mWindowAttributes)); 
    
    self.mSpecific.mWindowAttributes.border_pixel = 
        XBlackPixel(self.mSpecific.mDisplay, self.mSpecific.mSceen);

    self.mSpecific.mWindowAttributes.background_pixel = 
        XWhitePixel(self.mSpecific.mDisplay, self.mSpecific.mSceen);

    self.mSpecific.mWindowAttributes.override_redirect = 0;

    unsigned long window_mask = CWBackPixel | CWBorderPixel;

    self.mSpecific.mWindow = 
        XCreateWindow(self.mSpecific.mDisplay, 
                      XDefaultRootWindow(self.mSpecific.mDisplay), 
                      0, 0,
                      width,
                      height,
                      0, 
                      self.mSpecific.mDepth, 
                      InputOutput, 
                      CopyFromParent,
                      window_mask,
                      &self.mSpecific.mWindowAttributes);


    self.mSpecific.mGC = XCreateGC(self.mSpecific.mDisplay, 
                                 self.mSpecific.mWindow, 
                                 0, 0); 
    self.mSpecific.mBufWindow = 
        new unsigned char[width * height * (self.mBpp / 8)];

    memset(self.mSpecific.mBufWindow, 255, width * height * (self.mBpp / 8));
    
    m_rbuf_window.attach(self.mSpecific.mBufWindow,
                         width,
                         height,
                         self.mFlipY ? -width * (self.mBpp / 8) : width * (self.mBpp / 8));
        
    self.mSpecific.mXimgWindow = 
        XCreateImage(self.mSpecific.mDisplay, 
                     self.mSpecific.mVisual, //CopyFromParent, 
                     self.mSpecific.mDepth, 
                     ZPixmap, 
                     0,
                     (char*)self.mSpecific.mBufWindow, 
                     width,
                     height, 
                     self.mSpecific.mSysBpp,
                     width * (self.mSpecific.mSysBpp / 8));
    self.mSpecific.mXimgWindow.byte_order = self.mSpecific.mByteOrder;

    self.mSpecific.caption(m_caption); 
    self.mInitialWidth = width;
    self.mInitialHeight = height;
    
    if(!self.mSpecific.mInitialized)
    {
        on_init();
        self.mSpecific.mInitialized = true;
    }

    trans_affine_resizing(width, height);
    on_resize(width, height);
    self.mSpecific.mUpdateFlag = true;

    XSizeHints *hints = XAllocSizeHints();
    if(hints) 
    {
        if(flags & window_resize)
        {
            hints.min_width = 32;
            hints.min_height = 32;
            hints.max_width = 4096;
            hints.max_height = 4096;
        }
        else
        {
            hints.min_width  = width;
            hints.min_height = height;
            hints.max_width  = width;
            hints.max_height = height;
        }
        hints.flags = PMaxSize | PMinSize;

        XSetWMNormalHints(self.mSpecific.mDisplay, 
                          self.mSpecific.mWindow, 
                          hints);

        XFree(hints);
    }


    XMapWindow(self.mSpecific.mDisplay, 
               self.mSpecific.mWindow);

    XSelectInput(self.mSpecific.mDisplay, 
                 self.mSpecific.mWindow, 
                 xevent_mask);

    
    self.mSpecific.mCloseAtom = XInternAtom(self.mSpecific.mDisplay, 
                                           "WM_DELETE_WINDOW", 
                                           false);

    XSetWMProtocols(self.mSpecific.mDisplay, 
                    self.mSpecific.mWindow, 
                    &self.mSpecific.mCloseAtom, 
                    1);

    return true;
}]#




proc updateWindow[T,R](self: GenericPlatform[T,R]) =
  discard
#[ self.mSpecific.put_image(&m_rbuf_window);
    
    // When self.mWaitMode is true we can discard all the events 
    // came while the image is being drawn. In this case 
    // the X server does not accumulate mouse motion events.
    // When self.mWaitMode is false, i.e. we have some idle drawing
    // we cannot afford to miss any events
    XSync(self.mSpecific.mDisplay, self.mWaitMode);
]#

proc run[T,R](self: GenericPlatform[T,R]): int =
  result = 0
#[
    XFlush(self.mSpecific.mDisplay);
    
    bool quit = false;
    unsigned flags;
    int cur_x;
    int cur_y;

    while(!quit)
    {
        if(self.mSpecific.mUpdateFlag)
        {
            on_draw();
            update_window();
            self.mSpecific.mUpdateFlag = false;
        }

        if(!self.mWaitMode)
        {
            if(XPending(self.mSpecific.mDisplay) == 0)
            {
                on_idle();
                continue;
            }
        }

        XEvent x_event;
        XNextEvent(self.mSpecific.mDisplay, &x_event);
        
        // In the Idle mode discard all intermediate MotionNotify events
        if(!self.mWaitMode && x_event.type == MotionNotify)
        {
            XEvent te = x_event;
            for(;;)
            {
                if(XPending(self.mSpecific.mDisplay) == 0) break;
                XNextEvent(self.mSpecific.mDisplay, &te);
                if(te.type != MotionNotify) break;
            }
            x_event = te;
        }

        switch(x_event.type) 
        {
        case ConfigureNotify: 
            {
                if(x_event.xconfigure.width  != int(m_rbuf_window.width()) ||
                   x_event.xconfigure.height != int(m_rbuf_window.height()))
                {
                    int width  = x_event.xconfigure.width;
                    int height = x_event.xconfigure.height;

                    delete [] self.mSpecific.mBufWindow;
                    self.mSpecific.mXimgWindow.data = 0;
                    XDestroyImage(self.mSpecific.mXimgWindow);

                    self.mSpecific.mBufWindow = 
                        new unsigned char[width * height * (self.mBpp / 8)];

                    m_rbuf_window.attach(self.mSpecific.mBufWindow,
                                         width,
                                         height,
                                         self.mFlipY ? 
                                         -width * (self.mBpp / 8) : 
                                         width * (self.mBpp / 8));
        
                    self.mSpecific.mXimgWindow = 
                        XCreateImage(self.mSpecific.mDisplay, 
                                     self.mSpecific.mVisual, //CopyFromParent, 
                                     self.mSpecific.mDepth, 
                                     ZPixmap, 
                                     0,
                                     (char*)self.mSpecific.mBufWindow, 
                                     width,
                                     height, 
                                     self.mSpecific.mSysBpp,
                                     width * (self.mSpecific.mSysBpp / 8));
                    self.mSpecific.mXimgWindow.byte_order = self.mSpecific.mByteOrder;

                    trans_affine_resizing(width, height);
                    on_resize(width, height);
                    on_draw();
                    update_window();
                }
            }
            break;

        case Expose:
            self.mSpecific.put_image(&m_rbuf_window);
            XFlush(self.mSpecific.mDisplay);
            XSync(self.mSpecific.mDisplay, false);
            break;

        case KeyPress:
            {
                KeySym key = XLookupKeysym(&x_event.xkey, 0);
                flags = 0;
                if(x_event.xkey.state & Button1Mask) flags |= mouse_left;
                if(x_event.xkey.state & Button3Mask) flags |= mouse_right;
                if(x_event.xkey.state & ShiftMask)   flags |= kbd_shift;
                if(x_event.xkey.state & ControlMask) flags |= kbd_ctrl;

                bool left  = false;
                bool up    = false;
                bool right = false;
                bool down  = false;

                switch(self.mSpecific.mKeyMap[key & 0xFF])
                {
                case key_left:
                    left = true;
                    break;

                case key_up:
                    up = true;
                    break;

                case key_right:
                    right = true;
                    break;

                case key_down:
                    down = true;
                    break;

                case key_f2:                        
                    copy_window_to_img(max_images - 1);
                    save_img(max_images - 1, "screenshot");
                    break;
                }

                if(m_ctrls.on_arrow_keys(left, right, down, up))
                {
                    on_ctrl_change();
                    force_redraw();
                }
                else
                {
                    on_key(x_event.xkey.x, 
                           self.mFlipY ? 
                               m_rbuf_window.height() - x_event.xkey.y :
                               x_event.xkey.y,
                           self.mSpecific.mKeyMap[key & 0xFF],
                           flags);
                }
            }
            break;


        case ButtonPress:
            {
                flags = 0;
                if(x_event.xbutton.state & ShiftMask)   flags |= kbd_shift;
                if(x_event.xbutton.state & ControlMask) flags |= kbd_ctrl;
                if(x_event.xbutton.button == Button1)   flags |= mouse_left;
                if(x_event.xbutton.button == Button3)   flags |= mouse_right;

                cur_x = x_event.xbutton.x;
                cur_y = self.mFlipY ? m_rbuf_window.height() - x_event.xbutton.y :
                                   x_event.xbutton.y;

                if(flags & mouse_left)
                {
                    if(m_ctrls.on_mouse_button_down(cur_x, cur_y))
                    {
                        m_ctrls.set_cur(cur_x, cur_y);
                        on_ctrl_change();
                        force_redraw();
                    }
                    else
                    {
                        if(m_ctrls.in_rect(cur_x, cur_y))
                        {
                            if(m_ctrls.set_cur(cur_x, cur_y))
                            {
                                on_ctrl_change();
                                force_redraw();
                            }
                        }
                        else
                        {
                            on_mouse_button_down(cur_x, cur_y, flags);
                        }
                    }
                }
                if(flags & mouse_right)
                {
                    on_mouse_button_down(cur_x, cur_y, flags);
                }
                //self.mSpecific.mWaitMode = self.mWaitMode;
                //self.mWaitMode = true;
            }
            break;

            
        case MotionNotify:
            {
                flags = 0;
                if(x_event.xmotion.state & Button1Mask) flags |= mouse_left;
                if(x_event.xmotion.state & Button3Mask) flags |= mouse_right;
                if(x_event.xmotion.state & ShiftMask)   flags |= kbd_shift;
                if(x_event.xmotion.state & ControlMask) flags |= kbd_ctrl;

                cur_x = x_event.xbutton.x;
                cur_y = self.mFlipY ? m_rbuf_window.height() - x_event.xbutton.y :
                                   x_event.xbutton.y;

                if(m_ctrls.on_mouse_move(cur_x, cur_y, (flags & mouse_left) != 0))
                {
                    on_ctrl_change();
                    force_redraw();
                }
                else
                {
                    if(!m_ctrls.in_rect(cur_x, cur_y))
                    {
                        on_mouse_move(cur_x, cur_y, flags);
                    }
                }
            }
            break;
            
        case ButtonRelease:
            {
                flags = 0;
                if(x_event.xbutton.state & ShiftMask)   flags |= kbd_shift;
                if(x_event.xbutton.state & ControlMask) flags |= kbd_ctrl;
                if(x_event.xbutton.button == Button1)   flags |= mouse_left;
                if(x_event.xbutton.button == Button3)   flags |= mouse_right;

                cur_x = x_event.xbutton.x;
                cur_y = self.mFlipY ? m_rbuf_window.height() - x_event.xbutton.y :
                                   x_event.xbutton.y;

                if(flags & mouse_left)
                {
                    if(m_ctrls.on_mouse_button_up(cur_x, cur_y))
                    {
                        on_ctrl_change();
                        force_redraw();
                    }
                }
                if(flags & (mouse_left | mouse_right))
                {
                    on_mouse_button_up(cur_x, cur_y, flags);
                }
            }
            //self.mWaitMode = self.mSpecific.mWaitMode;
            break;

        case ClientMessage:
            if((x_event.xclient.format == 32) &&
            (x_event.xclient.data.l[0] == int(self.mSpecific.mCloseAtom)))
            {
                quit = true;
            }
            break;
        }           
    }


    unsigned i = platform_support::max_images;
    while(i--)
    {
        if(self.mSpecific.mBufImg[i]) 
        {
            delete [] self.mSpecific.mBufImg[i];
        }
    }

    delete [] self.mSpecific.mBufWindow;
    self.mSpecific.mXimgWindow.data = 0;
    XDestroyImage(self.mSpecific.mXimgWindow);
    XFreeGC(self.mSpecific.mDisplay, self.mSpecific.mGC);
    XDestroyWindow(self.mSpecific.mDisplay, self.mSpecific.mWindow);
    XCloseDisplay(self.mSpecific.mDisplay);
    
    return 0;
]#

proc loadImg[T,R](self: GenericPlatform[T,R], idx: int, file: string): bool =
  result = true
#[    if(idx < max_images)
    {
        char buf[1024];
        strcpy(buf, file);
        int len = strlen(buf);
        if(len < 4 || strcasecmp(buf + len - 4, ".ppm") != 0)
        {
            strcat(buf, ".ppm");
        }
        
        FILE* fd = fopen(buf, "rb");
        if(fd == 0) return false;

        if((len = fread(buf, 1, 1022, fd)) == 0)
        {
            fclose(fd);
            return false;
        }
        buf[len] = 0;
        
        if(buf[0] != 'P' && buf[1] != '6')
        {
            fclose(fd);
            return false;
        }
        
        char* ptr = buf + 2;
        
        while(*ptr && !isdigit(*ptr)) ptr++;
        if(*ptr == 0)
        {
            fclose(fd);
            return false;
        }
        
        unsigned width = atoi(ptr);
        if(width == 0 || width > 4096)
        {
            fclose(fd);
            return false;
        }
        while(*ptr && isdigit(*ptr)) ptr++;
        while(*ptr && !isdigit(*ptr)) ptr++;
        if(*ptr == 0)
        {
            fclose(fd);
            return false;
        }
        unsigned height = atoi(ptr);
        if(height == 0 || height > 4096)
        {
            fclose(fd);
            return false;
        }
        while(*ptr && isdigit(*ptr)) ptr++;
        while(*ptr && !isdigit(*ptr)) ptr++;
        if(atoi(ptr) != 255)
        {
            fclose(fd);
            return false;
        }
        while(*ptr && isdigit(*ptr)) ptr++;
        if(*ptr == 0)
        {
            fclose(fd);
            return false;
        }
        ptr++;
        fseek(fd, long(ptr - buf), SEEK_SET);
        
        create_img(idx, width, height);
        bool ret = true;
        
        if(self.mFormat == pix_format_rgb24)
        {
            fread(self.mSpecific.mBufImg[idx], 1, width * height * 3, fd);
        }
        else
        {
            unsigned char* buf_img = new unsigned char [width * height * 3];
            rendering_buffer rbuf_img;
            rbuf_img.attach(buf_img,
                            width,
                            height,
                            self.mFlipY ?
                              -width * 3 :
                               width * 3);
            
            fread(buf_img, 1, width * height * 3, fd);
            
            switch(self.mFormat)
            {
                case pix_format_rgb555:
                    color_conv(m_rbuf_img+idx, &rbuf_img, color_conv_rgb24_to_rgb555());
                    break;
                    
                case pix_format_rgb565:
                    color_conv(m_rbuf_img+idx, &rbuf_img, color_conv_rgb24_to_rgb565());
                    break;
                    
                case pix_format_bgr24:
                    color_conv(m_rbuf_img+idx, &rbuf_img, color_conv_rgb24_to_bgr24());
                    break;
                    
                case pix_format_rgba32:
                    color_conv(m_rbuf_img+idx, &rbuf_img, color_conv_rgb24_to_rgba32());
                    break;
                    
                case pix_format_argb32:
                    color_conv(m_rbuf_img+idx, &rbuf_img, color_conv_rgb24_to_argb32());
                    break;
                    
                case pix_format_bgra32:
                    color_conv(m_rbuf_img+idx, &rbuf_img, color_conv_rgb24_to_bgra32());
                    break;
                    
                case pix_format_abgr32:
                    color_conv(m_rbuf_img+idx, &rbuf_img, color_conv_rgb24_to_abgr32());
                    break;
                    
                default:
                    ret = false;
            }
            delete [] buf_img;
        }
                    
        fclose(fd);
        return ret;
    }
    return false;
  ]#
  
proc saveImg[T,R](self: GenericPlatform[T,R], idx: int, file: string): bool =
  result = true
#[    if(idx < max_images &&  rbuf_img(idx).buf())
    {
        char buf[1024];
        strcpy(buf, file);
        int len = strlen(buf);
        if(len < 4 || strcasecmp(buf + len - 4, ".ppm") != 0)
        {
            strcat(buf, ".ppm");
        }
        
        FILE* fd = fopen(buf, "wb");
        if(fd == 0) return false;
        
        unsigned w = rbuf_img(idx).width();
        unsigned h = rbuf_img(idx).height();
        
        fprintf(fd, "P6\n%d %d\n255\n", w, h);
            
        unsigned y; 
        unsigned char* tmp_buf = new unsigned char [w * 3];
        for(y = 0; y < rbuf_img(idx).height(); y++)
        {
            const unsigned char* src = rbuf_img(idx).row_ptr(self.mFlipY ? h - 1 - y : y);
            switch(self.mFormat)
            {
                default: break;
                case pix_format_rgb555:
                    color_conv_row(tmp_buf, src, w, color_conv_rgb555_to_rgb24());
                    break;
                    
                case pix_format_rgb565:
                    color_conv_row(tmp_buf, src, w, color_conv_rgb565_to_rgb24());
                    break;
                    
                case pix_format_bgr24:
                    color_conv_row(tmp_buf, src, w, color_conv_bgr24_to_rgb24());
                    break;
                    
                case pix_format_rgb24:
                    color_conv_row(tmp_buf, src, w, color_conv_rgb24_to_rgb24());
                    break;
                   
                case pix_format_rgba32:
                    color_conv_row(tmp_buf, src, w, color_conv_rgba32_to_rgb24());
                    break;
                    
                case pix_format_argb32:
                    color_conv_row(tmp_buf, src, w, color_conv_argb32_to_rgb24());
                    break;
                    
                case pix_format_bgra32:
                    color_conv_row(tmp_buf, src, w, color_conv_bgra32_to_rgb24());
                    break;
                    
                case pix_format_abgr32:
                    color_conv_row(tmp_buf, src, w, color_conv_abgr32_to_rgb24());
                    break;
            }
            fwrite(tmp_buf, 1, w * 3, fd);
        }
        delete [] tmp_buf;
        fclose(fd);
        return true;
    }
    return false;
  ]#  
  
proc createImg[T,R](self: GenericPlatform[T,R], idx: int, w = 0, h = 0): bool =
  result = true
#[    if(idx < max_images)
    {
        if(width  == 0) width  = rbuf_window().width();
        if(height == 0) height = rbuf_window().height();
        delete [] self.mSpecific.mBufImg[idx];
        self.mSpecific.mBufImg[idx] = 
            new unsigned char[width * height * (self.mBpp / 8)];

        m_rbuf_img[idx].attach(self.mSpecific.mBufImg[idx],
                               width,
                               height,
                               self.mFlipY ? 
                                   -width * (self.mBpp / 8) : 
                                    width * (self.mBpp / 8));
        return true;
    }
    return false;
}]#

proc imgExt[T,R](self: GenericPlatform[T,R]): string = ".bmp"

proc forceRedraw[T,R](self: GenericPlatform[T,R]) =
  self.mSpecific.mUpdateFlag = true

proc message[T,R](self: GenericPlatform[T,R], msg: string) =
  stderr.write msg & "\n"

proc startTimer[T,R](self: GenericPlatform[T,R]) =
  self.mSpecific.mSwStart = clock();

proc elapsedTime[T,R](self: GenericPlatform[T,R]): float64 =
  clock_t stop = clock();
  return double(stop - self.mSpecific.mSwStart) * 1000.0 / CLOCKS_PER_SEC;
    
proc fullFileName[T,R](self: GenericPlatform[T,R], fileName: string): string =
  result = fileName
