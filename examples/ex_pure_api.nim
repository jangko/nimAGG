import agg/[scanline_p, renderer_scanline, pixfmt_rgba,
  basics, color_rgba, renderer_base, rendering_buffer,
  scanline_p, rasterizer_scanline_aa]
import platform/winapi

const
  NULL = 0
  appName = "PureApi"
  mainClass = "PureApiMain"

var hInstance: HINST

proc fatalError*(msg: string) =
  echo msg
  quit(1)

proc registerWindowClass(hInstance: HINST, className: string, wndProc: WNDPROC) =
  var wndclass: WNDCLASS

  wndclass.style = CS_HREDRAW or CS_VREDRAW
  wndclass.lpfnWndProc = wndProc
  wndclass.cbClsExtra = 0
  wndclass.cbWndExtra = 0
  wndclass.hInstance = hInstance
  wndclass.hIcon = 0
  wndclass.hCursor = NULL
  wndclass.hbrBackground = NULL
  wndclass.lpszMenuName = nil
  wndclass.lpszClassName = WC(className)

  if registerClass(wndclass) == NULL:
    fatalError("cannot register window class")

proc createMainWindow(hInstance: HINST, className, title: string): HWND =
  result = createWindow(className, title, WS_OVERLAPPEDWINDOW or WS_VISIBLE,
    CW_USEDEFAULT, CW_USEDEFAULT, 500, 300,
    NULL.HWND, NULL.HMENU, hInstance, LPVOID(nil));

  if result == NULL:
    fatalError("cannot create window")

  showWindow(result, SW_SHOW)
  discard updateWindow(result)

proc mainWndProc(hWnd: HWND, iMsg: WINUINT, wParam: WPARAM, lParam: LPARAM): LPARAM {.stdcall.} =
  case iMsg:
  of WM_PAINT:
    var
      ps: PAINTSTRUCT
      hdc = beginPaint(hWnd, ps)
      rt: RECT
      bmpInfo: BITMAPINFO

    getClientRect(hWnd, rt.addr)

    let
      width = rt.right - rt.left
      height = rt.bottom - rt.top

    #Creating compatible DC and a bitmap to render the image

    bmpInfo.bmiHeader.biSize   = sizeof(BITMAPINFOHEADER).DWORD
    bmpInfo.bmiHeader.biWidth  = width
    bmpInfo.bmiHeader.biHeight = height
    bmpInfo.bmiHeader.biPlanes = 1
    bmpInfo.bmiHeader.biBitCount = 32
    bmpInfo.bmiHeader.biCompression = BI_RGB
    bmpInfo.bmiHeader.biSizeImage = 0
    bmpInfo.bmiHeader.biXPelsPerMeter = 0
    bmpInfo.bmiHeader.biYPelsPerMeter = 0
    bmpInfo.bmiHeader.biClrUsed = 0
    bmpInfo.bmiHeader.biClrImportant = 0

    var
      memDC = createCompatibleDC(hdc)
      buf: pointer = nil
      bmp = createDIBSection(memDC, bmpInfo, DIB_RGB_COLORS, buf, 0, 0)

    # Selecting the object before doing anything allows you
    # to use AGG together with native Windows GDI.
    var temp = HBITMAP(selectObject(memDC, bmp))

    #============================================================
    # AGG lowest level code.
    var rbuf = initRenderingBuffer()

    # Use negative stride in order
    # to keep Y-axis consistent with
    # WinGDI, i.e., going down.
    rbuf.attach(cast[ptr uint8](buf), width, height, -width*4)

    # Pixel format and basic primitives renderer
    var
      pixf = initPixFmtBgra32(rbuf)
      renb = initRendererBase(pixf)
      ren  = initRendererScanlineAASolid(renb) # Scanline renderer for solid filling.
      ras  = initRasterizerScanlineAA() # Rasterizer & scanline
      sl   = initScanlineP8()

    renb.clear(initRgba8(255, 255, 255, 255))

    # Polygon (triangle)
    ras.moveToD(20.7, 34.15)
    ras.lineToD(398.23, 123.43)
    ras.lineToD(165.45, 401.87)

    # Setting the attribute (color) & Rendering
    ren.color(initRgba8(200, 90, 60))
    renderScanlines(ras, sl, ren)
    #============================================================

    #------------------------------------------------------------
    # Display the image. If the image is B-G-R-A (32-bits per pixel)
    # one can use AlphaBlend instead of BitBlt. In case of AlphaBlend
    # one also should clear the image with zero alpha, i.e. rgba8(0,0,0,0)

    bitBlt(hdc, rt.left, rt.top, width, height, memDC, 0, 0, SRCCOPY)

    # Free resources
    selectObject(memDC, temp)
    deleteObject(bmp)
    deleteObject(memDC)
    endPaint(hWnd, ps)

  of WM_ERASEBKGND: # Don't forget to do nothing on Erase Background event :-)
    discard

  of WM_CLOSE:
    postQuitMessage(0)

  else:
    return defWindowProc(hWnd, iMsg, wParam, lParam)

  result = 0

proc main() =
  hInstance = getModuleHandle()
  if hInstance == NULL: fatalError("cannot get module handle")

  registerWindowClass(hInstance, mainClass, mainWndProc)
  var wMain = createMainWindow(hInstance, mainClass, appName)

  var msg: MSG
  while getMessage(msg, NULL, 0, 0):
    translateMessage(msg)
    dispatchMessage(msg)

main()