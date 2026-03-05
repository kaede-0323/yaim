import x11/xlib,
       x11/x,
       x11/keysym
import os

type
  Coord16* = array[4, uint16] # [左上X, 左上Y, 右上X, 右上Y]

type
  YaimCancel* = object of CatchableError

proc getCoords*(): Coord16 =
  var coords: Coord16

  let dpy = XOpenDisplay(nil)
  if dpy.isNil:
    quit("Cannot open X display")

  let root = XDefaultRootWindow(dpy)
  let screen = XDefaultScreen(dpy)

  let width  = XDisplayWidth(dpy, screen)
  let height = XDisplayHeight(dpy, screen)

  var attr: XSetWindowAttributes
  attr.override_redirect = 1
  attr.event_mask =
    ButtonPressMask or
    ButtonReleaseMask or
    PointerMotionMask or
    KeyPressMask

  let overlay = XCreateWindow(
    dpy, root,
    0,0,width.cuint,height.cuint,
    0,
    CopyFromParent,
    InputOnly,
    nil,
    (CWOverrideRedirect or CWEventMask).culong,
    addr attr
  )

  discard XMapRaised(dpy, overlay)

  var grabPointerErr = XGrabPointer(dpy, overlay, 1, ButtonPressMask or ButtonReleaseMask or PointerMotionMask, GrabModeAsync, GrabModeAsync, None, None, CurrentTime)
  var grabPointerAttempt = 0
  while(grabPointerErr != GrabSuccess and grabPointerAttempt < 10):
    sleep(1)
    grabPointerErr = XGrabPointer(dpy, overlay, 1, ButtonPressMask or ButtonReleaseMask or PointerMotionMask, GrabModeAsync, GrabModeAsync, None, None, CurrentTime)
    grabPointerAttempt += 1

  if(grabPointerErr != GrabSuccess):
    discard XUngrabPointer(dpy,CurrentTime)
    discard XDestroyWindow(dpy,overlay)
    discard XCloseDisplay(dpy)
    raise newException(CatchableError, "Failed to grab Pointer")

  var borderAttr: XSetWindowAttributes
  borderAttr.override_redirect = 1
  borderAttr.background_pixel = XWhitePixel(dpy, screen)

  var borders: array[4, Window]

  for i in 0..3:
    borders[i] = XCreateWindow(
      dpy, root,
      -100,-100,1,1,
      0,
      CopyFromParent,
      InputOutput,
      nil,
      (CWOverrideRedirect or CWBackPixel).culong,
      addr borderAttr
    )

  var ev: XEvent
  var x1,y1,x2,y2: cint
  var pressed = false
  var mapped = false
  const t = 1
  let escCode = XKeysymToKeycode(dpy, XK_Escape)

  while true:
    var keys: array[32, char]
    discard XQueryKeymap(dpy, keys)

    let escPressed = (keys[escCode.int div 8].uint8 and (1'u8 shr (escCode.int mod 8)))

    if escPressed.bool:
      discard XUngrabPointer(dpy,CurrentTime)
      for i in 0..3:
        discard XDestroyWindow(dpy,borders[i])
      discard XDestroyWindow(dpy,overlay)
      discard XCloseDisplay(dpy)
      raise newException(YaimCancel, "Cancel")

    if XPending(dpy) > 0:
      discard XNextEvent(dpy, addr ev)
  
      case ev.theType
      of ButtonPress:
        if ev.xbutton.button == Button1:
          x1 = ev.xbutton.x
          y1 = ev.xbutton.y
          pressed = true
        elif ev.xbutton.button == Button3:
          discard XUngrabPointer(dpy,CurrentTime)
          for i in 0..3:
            discard XDestroyWindow(dpy,borders[i])
          discard XDestroyWindow(dpy,overlay)
          discard XCloseDisplay(dpy)
          raise newException(YaimCancel, "Cancel")

      of MotionNotify:
        if pressed:
          x2 = ev.xmotion.x
          y2 = ev.xmotion.y
  
          let dx = min(x1,x2)
          let dy = min(y1,y2)
          let w  = max(t, abs(x2-x1))
          let h  = max(t, abs(y2-y1))
  
          discard XMoveResizeWindow(dpy,borders[0],dx.cint,dy.cint,w.cuint,t.cuint)
          discard XMoveResizeWindow(dpy,borders[1],dx.cint,(dy+h-t).cint,w.cuint,t.cuint)
          discard XMoveResizeWindow(dpy,borders[2],dx.cint,dy.cint,t.cuint,h.cuint)
          discard XMoveResizeWindow(dpy,borders[3],(dx+w-t).cint,dy.cint,t.cuint,h.cuint)
  
          if not mapped:
            for i in 0..3:
              discard XMapRaised(dpy,borders[i])
          mapped = true  

          discard XFlush(dpy)

      of ButtonRelease:
        if pressed:
          x2 = ev.xbutton.x
          y2 = ev.xbutton.y
          break
  
      of KeyPress:
        let key = XLookupKeysym(addr ev.xkey,0)
        if key == XK_Escape:
          raise newException(YaimCancel,"cancel")
  
      else:
        discard


  discard XUngrabPointer(dpy,CurrentTime)

  for i in 0..3:
    discard XDestroyWindow(dpy,borders[i])

  discard XDestroyWindow(dpy,overlay)
  discard XCloseDisplay(dpy)

  coords[0] = uint16(min(x1,x2))
  coords[1] = uint16(min(y1,y2))
  coords[2] = uint16(max(x1,x2))
  coords[3] = uint16(max(y1,y2))

  return coords
