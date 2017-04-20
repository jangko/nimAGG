import agg_basics, agg_rendering_buffer, agg_trans_viewport, ctrl_base
import agg_trans_affine, agg_color_conv_rgb8, agg_color_conv_rgb16
import agg_color_conv, os

# These are flags used in method init(). Not all of them are
# applicable on different platforms, for example the win32_api
# cannot use a hardware buffer (window_hw_buffer).
# The implementation should simply ignore unsupported flags.
type
  WindowFlag* = enum
    window_resize
    window_hw_buffer
    window_keep_aspect_ratio
    window_process_all_keys
    window_hidden

  WindowFlags* = set[WindowFlag]

# Possible formats of the rendering buffer. Initially I thought that it's
# reasonable to create the buffer and the rendering functions in
# accordance with the native pixel format of the system because it
# would have no overhead for pixel format conersion.
# But eventually I came to a conclusion that having a possibility to
# convert pixel formats on demand is a good idea. First, it was X11 where
# there lots of different formats and visuals and it would be great to
# render everything in, say, RGB-24 and display it automatically without
# any additional efforts. The second reason is to have a possibility to
# debug renderers for different pixel formats and colorspaces having only
# one computer and one system.
#
# This stuff is not included into the basic AGG functionality because the
# number of supported pixel formats (and/or colorspaces) can be great and
# if one needs to add new format it would be good only to add new
# rendering files without having to modify any existing ones (a general
# principle of incapsulation and isolation).
#
# Using a particular pixel format doesn't obligatory mean the necessity
# of software conversion. For example, win32 API can natively display
# gray8, 15-bit RGB, 24-bit BGR, and 32-bit BGRA formats.
# This list can be (and will be!) extended in future.
type
  PixFormat* = enum
    pix_format_undefined = 0,  # By default. No conversions are applied
    pix_format_bw,             # 1 bit per color B/W
    pix_format_gray8,          # Simple 256 level grayscale
    pix_format_gray16,         # Simple 65535 level grayscale
    pix_format_rgb555,         # 15 bit rgb. Depends on the byte ordering!
    pix_format_rgb565,         # 16 bit rgb. Depends on the byte ordering!
    pix_format_rgbAAA,         # 30 bit rgb. Depends on the byte ordering!
    pix_format_rgbBBA,         # 32 bit rgb. Depends on the byte ordering!
    pix_format_bgrAAA,         # 30 bit bgr. Depends on the byte ordering!
    pix_format_bgrABB,         # 32 bit bgr. Depends on the byte ordering!
    pix_format_rgb24,          # R-G-B, one byte per color component
    pix_format_bgr24,          # B-G-R, native win32 BMP format.
    pix_format_rgba32,         # R-G-B-A, one byte per color component
    pix_format_argb32,         # A-R-G-B, native MAC format
    pix_format_abgr32,         # A-B-G-R, one byte per color component
    pix_format_bgra32,         # B-G-R-A, native win32 BMP format
    pix_format_rgb48,          # R-G-B, 16 bits per color component
    pix_format_bgr48,          # B-G-R, native win32 BMP format.
    pix_format_rgba64,         # R-G-B-A, 16 bits byte per color component
    pix_format_argb64,         # A-R-G-B, native MAC format
    pix_format_abgr64,         # A-B-G-R, one byte per color component
    pix_format_bgra64,         # B-G-R-A, native win32 BMP format


# Mouse and keyboard flags. They can be different on different platforms
# and the ways they are obtained are also different. But in any case
# the system dependent flags should be mapped into these ones. The meaning
# of that is as follows. For example, if kbd_ctrl is set it means that the
# ctrl key is pressed and being held at the moment. They are also used in
# the overridden methods such as onMouseMove(), onMouseButtonDown(),
# on_mouse_button_dbl_click(), onMouseButtonUp(), on_key().
# In the method onMouseButtonUp() the mouse flags have different
# meaning. They mean that the respective button is being released, but
# the meaning of the keyboard flags remains the same.
# There's absolut minimal set of flags is used because they'll be most
# probably supported on different platforms. Even the mouse_right flag
# is restricted because Mac's mice have only one button, but AFAIK
# it can be simulated with holding a special key on the keydoard.
type
  InputFlag* = enum
    mouseLeft
    mouse_right
    kbd_shift
    kbd_ctrl

  InputFlags* = set[InputFlag]

# Keyboard codes. There's also a restricted set of codes that are most
# probably supported on different platforms. Any platform dependent codes
# should be converted into these ones. There're only those codes are
# defined that cannot be represented as printable ASCII-characters.
# All printable ASCII-set can be used in a regular C/C++ manner:
# ' ', 'A', '0' '+' and so on.
# Since the class is used for creating very simple demo-applications
# we don't need very rich possibilities here, just basic ones.
# Actually the numeric key codes are taken from the SDL library, so,
# the implementation of the SDL support does not require any mapping.
type
  KeyCode* = enum
    key_none           = 0

    # ASCII set. Should be supported everywhere
    key_backspace      = 8
    key_tab            = 9
    key_clear          = 12
    key_return         = 13
    key_pause          = 19
    key_escape         = 27

    # Keypad
    key_delete         = 127
    key_kp0            = 256
    key_kp1            = 257
    key_kp2            = 258
    key_kp3            = 259
    key_kp4            = 260
    key_kp5            = 261
    key_kp6            = 262
    key_kp7            = 263
    key_kp8            = 264
    key_kp9            = 265
    key_kp_period      = 266
    key_kp_divide      = 267
    key_kp_multiply    = 268
    key_kp_minus       = 269
    key_kp_plus        = 270
    key_kp_enter       = 271
    key_kp_equals      = 272

    # Arrow-keys and stuff
    key_up             = 273
    key_down           = 274
    key_right          = 275
    key_left           = 276
    key_insert         = 277
    key_home           = 278
    key_end            = 279
    key_page_up        = 280
    key_page_down      = 281

    # Functional keys. You'd better aproc using
    # f11...f15 in your applications if you want
    # the applications to be portable
    key_f1             = 282
    key_f2             = 283
    key_f3             = 284
    key_f4             = 285
    key_f5             = 286
    key_f6             = 287
    key_f7             = 288
    key_f8             = 289
    key_f9             = 290
    key_f10            = 291
    key_f11            = 292
    key_f12            = 293
    key_f13            = 294
    key_f14            = 295
    key_f15            = 296

    # The possibility of using these keys is
    # very restricted. Actually it's guaranteed
    # only in win32_api and win32_sdl implementations
    key_numlock        = 300
    key_capslock       = 301
    key_scrollock      = 302

# A helper class that contains pointers to a number of controls.
# This class is used to ease the event handling with controls.
# The implementation should simply call the appropriate methods
# of this class when appropriate events occur.
const
  maxCtrl = 64

type
  CtrlContainer = object
    mCtrl: array[maxCtrl, CtrlBase]
    mNumCtrl: int
    mCurCtrl: int


proc initCtrlContainer*(): CtrlContainer =
  result.mNumCtrl = 0
  result.mCurCtrl = -1

proc add*(self: var CtrlContainer, c: CtrlBase) =
  if self.mNumCtrl < maxCtrl:
    self.mCtrl[self.mNumCtrl] = c
    inc self.mNumCtrl

proc inRect*(self: CtrlContainer, x, y: float64): bool =
  for i in 0.. <self.mNumCtrl:
    if self.mCtrl[i].inRect(x, y): return true
  result = false

proc onMouseButtonDown*(self: CtrlContainer, x, y: float64): bool =
  for i in 0.. <self.mNumCtrl:
    if self.mCtrl[i].onMouseButtonDown(x, y): return true
  result = false

proc onMouseButtonUp*(self: CtrlContainer, x, y: float64): bool =
  result = false
  for i in 0.. <self.mNumCtrl:
    if self.mCtrl[i].onMouseButtonUp(x, y): result = true

proc onMouseMove*(self: CtrlContainer, x, y: float64, buttonFlag: bool): bool =
  for i in 0.. <self.mNumCtrl:
    if self.mCtrl[i].onMouseMove(x, y, buttonFlag): return true
  result = false

proc onArrowKeys*(self: CtrlContainer, left, right, down, up: bool): bool =
  if self.mCurCtrl >= 0:
    return self.mCtrl[self.mCurCtrl].onArrowKeys(left, right, down, up)
  result = false

proc setCur*(self: var CtrlContainer, x, y: float64): bool =
  for i in 0.. <self.mNumCtrl:
    if self.mCtrl[i].inRect(x, y):
      if self.mCurCtrl != i:
        self.mCurCtrl = i
        return true
      return false

  if self.mCurCtrl != -1:
    self.mCurCtrl = -1
    return true
  result = false

# A predeclaration of the platform dependent class. Since we do not
# know anything here the only we can have is just a pointer to this
# class as a data member. It should be created and destroyed explicitly
# in the constructor/destructor of the platform_support class.
# Although the pointer to platform_specific is public the application
# cannot have access to its members or methods since it does not know
# anything about them and it's a perfect incapsulation :-)
#class platform_specific;


# This class is a base one to the apllication classes. It can be used
# as follows:
#
#  class the_application : public agg::platform_support
#  {
#  public:
#      the_application(unsigned bpp, bool flip_y) :
#          platform_support(bpp, flip_y)
#      . . .
#
#      #override stuff . . .
#      virtual proc on_init()
#      {
#         . . .
#      }
#
#      virtual proc on_draw()
#      {
#          . . .
#      }
#
#      virtual proc on_resize(int sx, int sy)
#      {
#          . . .
#      }
#      # . . . and so on, see virtual functions
#
#
#      #any your own stuff . . .
#  };
#
#
#  int agg_main(int argc, char* argv[])
#  {
#      the_application app(pix_format_rgb24, true)
#      app.caption("AGG Example. Lion")
#
#      if(app.init(500, 400, agg::window_resize))
#      {
#          return app.run()
#      }
#      return 1;
#  }
#
# The reason to have agg_main() instead of just main() is that SDL
# for Windows requires including SDL.h if you define main(). Since
# the demo applications cannot rely on any platform/library specific
# stuff it's impossible to include SDL.h into the application files.
# The demo applications are simple and their use is restricted, so,
# this approach is quite reasonable.

const
  maxImages* = 16

type
  PlatformBase* = ref object of RootObj

  GenericPlatform*[T] = ref object of PlatformBase
    mCtrls: CtrlContainer

    # Sorry, I'm too tired to describe the private
    # data members. See the implementations for different
    # platforms for details.
    mFormat: PixFormat
    mBpp: int
    mRbufWindow: RenderingBuffer
    mRbufImage: array[maxImages, RenderingBuffer]
    mWindowFlags: WindowFlags
    mWaitMode: bool
    mFlipY: bool
    mCaption: string
    mInitialWidth: int
    mInitialHeight: int
    mResizeMtx: TransAffine
    mSpecific: T

# format - see enum PixFormat
# flip_y - true if you want to have the Y-axis flipped vertically.
proc init*[T](self: GenericPlatform[T], format: PixFormat, flipY: bool)

# Setting the windows caption (title). Should be able
# to be called at least before calling init().
# It's perfect if they can be called anytime.
proc caption*[T](self: GenericPlatform[T], cap: string)
proc caption*[T](self: GenericPlatform[T]): string =
  self.mCaption

# These 3 methods handle working with images. The image
# formats are the simplest ones, such as .BMP in Windows or
# .ppm in Linux. In the applications the names of the files
# should not have any file extensions. Method load_img() can
# be called before init(), so, the application could be able
# to determine the initial size of the window depending on
# the size of the loaded image.
# The argument "idx" is the number of the image 0...maxImages-1
proc loadImg*[T](self: GenericPlatform[T], idx: int, file: string): bool
proc saveImg*[T](self: GenericPlatform[T], idx: int, file: string): bool
proc createImg*[T](self: GenericPlatform[T], idx: int, w = 0, h = 0): bool


# init() and run(). See description before the class for details.
# The necessity of calling init() after creation is that it's
# impossible to call the overridden virtual function (on_init())
# from the constructor. On the other hand it's very useful to have
# some on_init() event handler when the window is created but
# not yet displayed. The rbuf_window() method (see below) is
# accessible from on_init().
proc init*[T](self: GenericPlatform[T], width, height: int, flags: WindowFlags, fileName: string): bool
proc run*[T](self: GenericPlatform[T]): int

# The very same parameters that were used in the constructor
proc format*[T](self: GenericPlatform[T]): PixFormat =
  self.mFormat

proc flipY*[T](self: GenericPlatform[T]): bool =
  self.mFlipY

proc bpp*[T](self: GenericPlatform[T]): int =
  self.mBpp

# The following provides a very simple mechanism of doing someting
# in background. It's not multithreading. When wait_mode is true
# the class waits for the events and it does not ever call on_idle().
# When it's false it calls on_idle() when the event queue is empty.
# The mode can be changed anytime. This mechanism is satisfactory
# to create very simple animations.
proc waitMode*[T](self: GenericPlatform[T]): bool =
  self.mWaitMode

proc waitMode*[T](self: GenericPlatform[T], waitMode: bool) =
  self.mWaitMode = waitMode

# These two functions control updating of the window.
# force_redraw() is an analog of the Win32 InvalidateRect() function.
# Being called it sets a flag (or sends a message) which results
# in calling on_draw() and updating the content of the window
# when the next event cycle comes.
# update_window() results in just putting immediately the content
# of the currently rendered buffer to the window without calling
# on_draw().
proc forceRedraw*[T](self: GenericPlatform[T])
proc updateWindow*[T](self: GenericPlatform[T])


# So, finally, how to draw anythig with AGG? Very simple.
# rbuf_window() returns a reference to the main rendering
# buffer which can be attached to any rendering class.
# rbuf_img() returns a reference to the previously created
# or loaded image buffer (see load_img()). The image buffers
# are not displayed directly, they should be copied to or
# combined somehow with the rbuf_window(). rbuf_window() is
# the only buffer that can be actually displayed.
proc rbufWindow*[T](self: GenericPlatform[T]): var RenderingBuffer =
  self.mRbufWindow

proc rbufImg*[T](self: GenericPlatform[T], idx: int): var RenderingBuffer =
  self.mRbufImage[idx]

# Returns file extension used in the implementation for the particular
# system.
proc imgExt*[T](self: GenericPlatform[T]): string

proc copyImgToWindow*[T](self: GenericPlatform[T], idx: int) =
  if idx < maxImages and self.rbufImg(idx).buf() != nil:
    self.rbufWindow().copyFrom(self.rbufImg(idx))

proc copyWindowToImg*[T](self: GenericPlatform[T], idx: int) =
  if idx < maxImages:
    discard self.createImg(idx, self.rbufWindow().width(), self.rbufWindow().height())
    self.rbufImg(idx).copyFrom(self.rbufWindow())

proc copyImgToImg*[T](self: GenericPlatform[T], idxTo, idxFrom: int) =
  if idxFrom < maxImages and idxTo < maxImages and self.rbufImg(idxFrom).buf() != nil:
    discard self.createImg(idxTo, self.rbufImg(idxFrom).width(), self.rbufImg(idxFrom).height())
    self.rbufImg(idxTo).copyFrom(self.rbufImg(idxFrom))

# Event handlers. They are not pure functions, so you don't have
# to override them all.
# In my demo applications these functions are defined inside
# the the_application class (implicit inlining) which is in general
# very bad practice, I mean vitual inline methods. At least it does
# not make sense.
# But in this case it's quite appropriate bacause we have the only
# instance of the the_application class and it is in the same file
# where this class is defined.
method onInit*(self: PlatformBase) {.base.} = discard
method onResize*(self: PlatformBase, sx, sy: int) {.base.} = discard
method onIdle*(self: PlatformBase) {.base.} = discard
method onMouseMove*(self: PlatformBase, x, y: int, flags: InputFlags) {.base.} = discard
method onMouseButtonDown*(self: PlatformBase, x, y: int, flags: InputFlags) {.base.} = discard
method onMouseButtonUp*(self: PlatformBase, x, y: int, flags: InputFlags) {.base.} = discard
method onKey*(self: PlatformBase, x, y: int, key: int, flags: InputFlags) {.base.} = discard
method onCtrlChange*(self: PlatformBase) {.base.} = discard
method onDraw*(self: PlatformBase) {.base.} = discard
method onPostDraw*(self: PlatformBase, rawHandler: pointer) {.base.} = discard

# Adding control elements. A control element once added will be
# working and reacting to the mouse and keyboard events. Still, you
# will have to render them in the on_draw() using function
# render_ctrl() because platform_support doesn't know anything about
# renderers you use. The controls will be also scaled automatically
# if they provide a proper scaling mechanism (all the controls
# included into the basic AGG package do).
# If you don't need a particular control to be scaled automatically
# call ctrl::no_transform() after adding.
proc addCtrl*[T](self: GenericPlatform[T], c: CtrlBase) =
  self.mCtrls.add(c)
  c.transform(self.mResizeMtx)

# Auxiliary functions. trans_affine_resizing() modifier sets up the resizing
# matrix on the basis of the given width and height and the initial
# width and height of the window. The implementation should simply
# call this function every time when it catches the resizing event
# passing in the new values of width and height of the window.
# Nothing prevents you from "cheating" the scaling matrix if you
# call this function from somewhere with wrong arguments.
# trans_affine_resizing() accessor simply returns current resizing matrix
# which can be used to apply additional scaling of any of your
# stuff when the window is being resized.
# width(), height(), initial_width(), and initial_height() must be
# clear to understand with no comments :-)

proc transAffineResizing*[T](self: GenericPlatform[T], width, height: int) =
  if window_keep_aspect_ratio in self.mWindowFlags:
    #double sx = double(width) / double(self.mInitialWidth)
    #double sy = double(height) / double(self.mInitialHeight)
    #if(sy < sx) sx = sy;
    #self.mResizeMtx = trans_affine_scaling(sx, sx)
    var vp = initTransViewport()
    vp.preserveAspectRatio(0.5, 0.5, aspectRatioMeet)
    vp.setDeviceViewport(0, 0, width.float64, height.float64)
    vp.setWorldViewport(0, 0, self.mInitialWidth.float64, self.mInitialHeight.float64)
    self.mResizeMtx = vp.toAffine()
  else:
    self.mResizeMtx = transAffineScaling(float64(width) / float64(self.mInitialWidth),
     float64(height) / float64(self.mInitialHeight))

proc transAffineResizing*[T](self: GenericPlatform[T]): var TransAffine =
  self.mResizeMtx

proc width*[T](self: GenericPlatform[T]): float64 =
  self.mRbufWindow.width().float64

proc height*[T](self: GenericPlatform[T]): float64 =
  self.mRbufWindow.height().float64

proc initialWidth*[T](self: GenericPlatform[T]): float64 =
  self.mInitialWidth.float64

proc initialHeight*[T](self: GenericPlatform[T]): float64 =
  self.mInitialHeight.float64

proc windowFlags*[T](self: GenericPlatform[T]): WindowFlags =
  self.mWindowFlags

# Get raw display handler depending on the system.
# For win32 its an HDC, for other systems it can be a pointer to some
# structure. See the implementation files for detals.
# It's provided "as is", so, first you should check if it's not null.
# If it's null the raw_display_handler is not supported. Also, there's
# no guarantee that this function is implemented, so, in some
# implementations you may have simply an unresolved symbol when linking.
proc rawDisplayHandler*[T](self: GenericPlatform[T]): pointer

# display message box or print the message to the console
# (depending on implementation)
proc message*[T](self: GenericPlatform[T], msg: string)

# Stopwatch functions. Function elapsed_time() returns time elapsed
# since the latest start_timer() invocation in millisecods.
# The resolutoin depends on the implementation.
# In Win32 it uses QueryPerformanceFrequency() / QueryPerformanceCounter().
proc startTimer*[T](self: GenericPlatform[T])
proc elapsedTime*[T](self: GenericPlatform[T]): float64


# Get the full file name. In most cases it simply returns
# file_name. As it's appropriate in many systems if you open
# a file by its name without specifying the path, it tries to
# open it in the current directory. The demos usually expect
# all the supplementary files to be placed in the current
# directory, that is usually coincides with the directory where
# the the executable is. However, in some systems (BeOS) it's not so.
# For those kinds of systems full_file_name() can help access files
# preserving commonly used policy.
# So, it's a good idea to use in the demos the following:
# FILE* fd = fopen(full_file_name("some.file"), "r")
# instead of
# FILE* fd = fopen("some.file", "r")
proc fullFileName*[T](self: GenericPlatform[T], fileName: string): string

include agg_win_platform_support
type
  PlatformSupport* = GenericPlatform[PlatformSpecific]
