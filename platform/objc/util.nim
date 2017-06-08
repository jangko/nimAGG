import objc, foundation, strutils, macros, typetraits

type
  NSObject* = object of RootObj
    id*: ID

  NSWindow* = object of NSObject

  NSString* = object of NSObject

  NSView* = object of NSObject

  NSAutoReleasePool* = object of NSObject

  NSApplication* = object of NSObject

  NSOpenGLPixelFormat* = object of NSObject

  NSAppDelegate* = object of NSObject

  NSOpenGLView* = object of NSView

proc print*(obj: NSObject) =
  echo $cast[int](obj.id)

proc isNil*(obj: NSObject): bool =
  result = obj.id.isNil()

proc `@`*(a: string): NSString =
  result.id = objc_msgSend(getClass("NSString").ID, $$"stringWithUTF8String:", a.cstring)

macro `[]`*(id: ID, cmd: SEL, args: varargs[untyped]): untyped =
  if args.len > 0:
    let p = "discard objc_msgSend($1, $2 $3)"
    var z = ""
    for a in args:
      z.add(", ")
      z.add(a.toStrLit().strVal)
    var w = p % [id.toStrLit().strVal, cmd.toStrLit().strVal, z]
    result = parseStmt(w)
  else:
    let p = "discard objc_msgSend($1, $2)"
    var w = p % [id.toStrLit().strVal, cmd.toStrLit().strVal]
    result = parseStmt(w)

macro `[]`*(obj: NSObject, cmd: SEL, args: varargs[untyped]): untyped =
  let ids = obj.toStrLit().strVal & ".id"
  if args.len > 0:
    let p = "discard objc_msgSend($1, $2 $3)"
    var z = ""
    for a in args:
      z.add(", ")
      z.add(a.toStrLit().strVal)
    var w = p % [ids, cmd.toStrLit().strVal, z]
    result = parseStmt(w)
  else:
    let p = "discard objc_msgSend($1, $2)"
    var w = p % [ids, cmd.toStrLit().strVal]
    result = parseStmt(w)

proc call(cls: typedesc, cmd: SEL): ID =
  objc_msgSend(getClass(cls.name).ID, cmd)

proc newClass*(cls: string): ID =
  objc_msgSend(objc_msgSend(getClass(cls).ID, $$"alloc"), $$"init")

proc setIvar*[T](obj: NSObject, name: string, val: T) =
  var cls = getClass(obj.id)
  var ivar = cls.getIvar(name)
  setIvar(obj.id, ivar, cast[ID](val))

proc newAutoReleasePool*(): NSAutoReleasePool =
  result.id = newClass("NSAutoReleasePool")

proc newApplication*(): NSApplication =
  result.id = call(NSApplication, $$"sharedApplication")

proc run*(app: NSApplication) =
  app[$$"run"]

proc setActivationPolicy*(app: NSApplication, policy: NSApplicationActivationPolicy) =
  app[$$"setActivationPolicy:", policy]

proc setDelegate*(app: NSApplication, delegate: NSAppDelegate) =
  app[$$"setDelegate:", delegate.id]

proc newAppDelegate*(): NSAppDelegate =
  result.id = newClass("AppDelegate")

proc drain*(pool: NSAutoReleasePool) =
  pool[$$"drain"]

proc setTitle*(win: NSWindow, cap: string) =
  win[$$"setTitle:", @cap.id]

proc display*(win: NSWindow) =
  win[$$"display"]

proc orderFrontRegardless*(win: NSWindow) =
  win[$$"orderFrontRegardless"]

proc setContentView*(win: NSWindow, view: NSView) =
  win[$$"setContentView:", view.id]

proc makeFirstResponder*(win: NSWindow, view: NSView) =
  win[$$"makeFirstResponder:", view.id]

proc makeKeyWindow*(win: NSWindow) =
  win[$$"makeKeyWindow"]

proc setNeedsDisplay*(view: NSView, needDisplay: BOOL) =
  view[$$"setNeedsDisplay:", needDisplay]

proc autoRelease*(obj: NSObject) =
  discard objc_msgSend(obj.id, $$"autorelease")

proc objc_alloc(cls: string): ID =
  objc_msgSend(getClass(cls).ID, $$"alloc")

proc initWithAttributes(pf: NSOpenGLPixelFormat, attrs: ptr NSOpenGLPixelFormatAttribute) =
  pf[$$"initWithAttributes:", attrs]

proc init*(x: typedesc[NSWindow], rect: CMRect, mask: int, backing: int, xdefer: BOOL): NSWindow =
  var wnd = objc_alloc("NSWindow")
  var cmd = $$"initWithContentRect:styleMask:backing:defer:"
  result.id = wnd.objc_msgSend(cmd, rect, mask.uint64, backing.uint64, xdefer)

proc createPixelFormat*(): NSOpenGLPixelFormat =
  var attrs: array[10, NSOpenGLPixelFormatAttribute]
  var numAttr = 0

  attrs[numAttr] = NSOpenGLPFADoubleBuffer; inc numAttr
  attrs[numAttr] = NSOpenGLPFADepthSize; inc numAttr
  attrs[numAttr] = 24; inc numAttr
  attrs[numAttr] = NSOpenGLPFAAccumSize; inc numAttr
  attrs[numAttr] = 32; inc numAttr
  attrs[numAttr] = 0; inc numAttr

  result.id = objc_alloc("NSOpenGLPixelFormat")

  result.initWithAttributes(attrs[0].addr)
  result.autoRelease()

  if result.isNil():
    echo "error: cannot create required pixel format for the OpenGL view."
    quit(1)

proc newOpenGLView*(): NSOpenGLView =
  result.id = objc_alloc("NSOpenGLView")

proc initWithFrame*(view: NSOpenGLView, rect: CMRect, pixelFormat: NSOpenGLPixelFormat) =
  var cmd = $$"initWithFrame:pixelFormat:"
  #view[cmd, rect, pixelFormat.id]
  var id = objc_msgSend(view.id, cmd, rect, pixelFormat.id)

proc setWantsBestResolutionOpenGLSurface*(view: NSOpenGLView, wantBest: BOOL) =
  view[$$"setWantsBestResolutionOpenGLSurface:", wantBest]

proc makeCurrentContext*(view: NSOpenGLView) =
  var id = objc_msgSend(view.id, $$"openGLContext")
  discard objc_msgSend(id, $$"makeCurrentContext")
