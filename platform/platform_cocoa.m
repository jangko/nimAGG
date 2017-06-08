#import <Cocoa/Cocoa.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>

typedef void(*DrawRectT)(void*);
typedef void(*ReshapeT)(void*, int, int);

typedef struct CocoaFFI {
  NSWindow* mWindow;
  NSOpenGLView* mView;
  NSAutoreleasePool* mPool;
  NSApplication* mApp;
  void* mPlatform;
  DrawRectT mDrawRect;
  ReshapeT mReshape;
} CocoaFFI;

@interface MyWindow: NSWindow

- (BOOL) canBecomeKeyWindow;
- (BOOL) canBecomeMainWindow;
@end

@implementation MyWindow
- (BOOL) canBecomeKeyWindow
{
  return YES;
}
- (BOOL) canBecomeMainWindow
{
  return YES;
}
@end


@interface AppDelegate : NSObject <NSApplicationDelegate>{
}
@end

@implementation AppDelegate
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSNotification*) aNotification {
  return YES;
}
@end

@interface MyView: NSOpenGLView {
  @public CocoaFFI* mFFI;
}
@end

@implementation MyView
-(BOOL) acceptFirstResponder
{
  return YES;
}

-(void) drawRect: (NSRect) bounds
{
  mFFI->mDrawRect(mFFI->mPlatform);
}

- (void) reshape
{
  // get info about the new frame
  NSRect  frame = [self frame];

  const int width   = (int)(frame.size.width),
            height  = (int)(frame.size.height );

  // Compute aspect ratio of the new window
  if(height == 0 || width == 0) {
    return;              // To prevent divide by 0
  }

  glViewport(0, 0, width, height);

  // Set the aspect ratio of the clipping volume to match the viewport
  glMatrixMode(GL_PROJECTION);  // To operate on the Projection matrix
  glLoadIdentity();             // Reset
  gluOrtho2D(0.0, (GLdouble)width, 0.0, (GLdouble)height);

  glMatrixMode(GL_TEXTURE);
  glLoadIdentity();
  glScalef(1.0/(GLfloat)width, 1.0/(GLfloat)height, 1.0);

  mFFI->mReshape(mFFI->mPlatform, width, height);
}

- (void)mouseDown:(NSEvent *)theEvent
{
      [[self nextResponder] mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
      [[self nextResponder] mouseUp:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
      [[self nextResponder] mouseDragged:theEvent];
}

- (void) keyDown:(NSEvent *)event
{
  NSLog(@"%d", event.keyCode);
  [[self nextResponder] keyDown:event];
}
@end

NSOpenGLPixelFormat * createPixelFormat() {
   NSOpenGLPixelFormatAttribute attrs[] =  {
      NSOpenGLPFADoubleBuffer,
      NSOpenGLPFADepthSize, 24,
      NSOpenGLPFAAccumSize,  32,
      0
   };

   NSOpenGLPixelFormat *
      pf =  [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease ];

   if (pf == NULL) {
      NSLog(@"cocoglut: error: cannot create required pixel format for the OpenGL view.");
      exit(1);
   }

   return pf;
}

void cocoaInit(CocoaFFI* self, int showWindow, char* title, int w, int h) {
  self->mPool = [[NSAutoreleasePool alloc] init];
  self->mApp  = [NSApplication sharedApplication];
  [self->mApp setActivationPolicy:NSApplicationActivationPolicyRegular];

  NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask |
      NSMiniaturizableWindowMask | NSResizableWindowMask;

  NSRect windowRect = NSMakeRect(100, 100, w, h);
  MyWindow* window = [ [MyWindow alloc] initWithContentRect: windowRect
                                                  styleMask: windowStyle
                                                    backing: NSBackingStoreBuffered
                                                      defer: YES];

  NSString* nsTitle = [[NSString alloc] initWithUTF8String:title];
  [window setTitle: nsTitle];

  if(showWindow) {
    [window display];
    [window orderFrontRegardless];
  }

  NSOpenGLPixelFormat *pf = createPixelFormat();
  MyView* newView = [[MyView alloc] initWithFrame:windowRect pixelFormat: pf];
  [newView setWantsBestResolutionOpenGLSurface: YES];
  [window setContentView: newView];
  [window makeFirstResponder: newView];
  [window makeKeyWindow];

  AppDelegate* appDel = [[AppDelegate alloc] init];
  [NSApp setDelegate: appDel];

  newView->mFFI = self;
  self->mWindow = window;
  self->mView   = newView;
}

void run(CocoaFFI* self) {
  [self->mApp run];
}

GLuint cocoaInitGL(CocoaFFI* self, unsigned char* data, int w, int h, GLenum format) {
  GLuint res = 0;

  glClearColor(0.0, 0.0, 0.0, 1.0);                  // Set background color to black and opaque
  glClearDepth(1.0);                                 // Set background depth to farthest
  glEnable(GL_DEPTH_TEST);                           // Enable depth testing for z-culling
  glDepthFunc(GL_LEQUAL);                            // Set the type of depth-test
  glShadeModel(GL_SMOOTH);                           // Enable smooth shading
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST); // Nice perspective corrections

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);// Clear color and depth buffers
  glMatrixMode(GL_MODELVIEW);                          // To operate on model-view matrix
  glLoadIdentity();                                    // Reset the model-view matrix

  glEnable(GL_TEXTURE_2D);
  glGenTextures(1, &res);
  glBindTexture(GL_TEXTURE_2D, res);
  glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLint)w);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,  GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D,
    0, GL_RGBA8,
    (GLsizei)w, (GLsizei)h,
    0, format,
    GL_UNSIGNED_BYTE, data);

  glMatrixMode(GL_TEXTURE);
  glLoadIdentity();
  glScalef(1.0/(GLfloat)w, 1.0/(GLfloat)h, 1.0);

  return res;
}

void cocoaDeinit(CocoaFFI* self, GLuint texID) {
  glDeleteTextures(1, &texID);
  [self->mPool drain];
}

void forceRedraw(CocoaFFI* self) {
  if(self->mView != 0) {
    [self->mView setNeedsDisplay: YES];
  }
}

void setTitle(CocoaFFI* self, char* title) {
  if(self->mWindow != 0) {
    NSString* cap = [[NSString alloc] initWithUTF8String:title];
    [self->mWindow setTitle: cap];
  }
}

void blitImage(GLuint id, char* data, GLint x1, GLint y1, GLint x2, GLint y2, GLenum format) {
  GLuint texID = 0;
  GLuint w = x2 - x1;
  GLuint h = y2 - y1;

  glEnable(GL_TEXTURE_2D);
  glGenTextures(1, &texID);
  glBindTexture(GL_TEXTURE_2D, texID);

  glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLint)w);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D,
    0, GL_RGBA8,
    (GLsizei)w, (GLsizei)h,
    0, GL_BGR,
    GL_UNSIGNED_BYTE, data);

  glMatrixMode(GL_TEXTURE);
  glLoadIdentity();
  glScalef(1.0/(GLfloat)w, 1.0/(GLfloat)h, 1.0);

  glColor3f(1.0f, 1.0f, 1.0f);
  glBegin(GL_POLYGON);
    glTexCoord2i(0,   0); glVertex2i(x1, y1);
    glTexCoord2i(x2,  0); glVertex2i(x2, y1);
    glTexCoord2i(x2, y2); glVertex2i(x2, y2);
    glTexCoord2i(0,  y2); glVertex2i(x1, y2);
  glEnd();

  glFlush();
  glSwapAPPLE();

  glDeleteTextures(1, &texID);
}
