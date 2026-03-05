import x11/xlib,
       x11/x,
       x11/keysym
import os

type
  Coord16* = array[4, uint16] # [左上X, 左上Y, 右上X, 右上Y]

type
  YaimCancel* = object of CatchableError

proc getCoords*(windowId: int): Coord16 =
  var coords: Coord16

  let dpy = XOpenDisplay(nil)
  if dpy.isNil:
    quit("Cannot open X Display")

  let root = if windowId == -1: XDefaultRootWindow(dpy) else: Window(windowId)
  let screen = XDefaultScreen(dpy)
  let width = XDisplayWidth(dpy, screen)
  let height = XDisplayHeight(dpy, screen)

  var overlayAttrs: XSetWindowAttributes
  overlayAttrs.override_redirect = 1
  overlayAttrs.event_mask = ButtonPressMask or ButtonReleaseMask or PointerMotionMask
  
  let overlay = XCreateWindow(
    dpy, root,
    0.cint, 0.cint, width.cuint, height.cuint, 0.cuint,
    CopyFromParent.cint, InputOnly.cuint, nil,
    (CWOverrideRedirect or CWEventMask).culong, addr overlayAttrs
  )
  discard XMapRaised(dpy, overlay)

  let t: cuint = 1
  var borderAttrs: XSetWindowAttributes
  borderAttrs.override_redirect = 1
  borderAttrs.background_pixel = XWhitePixel(dpy, screen) # 枠の色（白）

  var borders: array[4, Window]
  for i in 0..3:
    borders[i] = XCreateWindow(
      dpy, root,
      -100.cint, -100.cint, 1.cuint, 1.cuint, # 初期位置
      0.cuint, CopyFromParent.cint, InputOutput.cuint, nil,
      (CWOverrideRedirect or CWBackPixel).culong, addr borderAttrs
    )

  var grabPointerErr = XGrabPointer(dpy, overlay, 1, ButtonPressMask or ButtonReleaseMask or PointerMotionMask, GrabModeAsync, GrabModeAsync, 0, 0, CurrentTime)
  var grabPointerTries = 0
  while ( grabPointerErr != GrabSuccess and grabPointerTries < 10):
    1.sleep
    grabPointerErr = XGrabPointer(dpy, overlay, 1, ButtonPressMask or ButtonReleaseMask or PointerMotionMask, GrabModeAsync, GrabModeAsync, 0, 0, CurrentTime)
    inc grabPointerTries
  
  if (grabPointerErr != GrabSuccess):
    discard XDestroyWindow(dpy, overlay)
    discard XCloseDisplay(dpy)
    raise newException(CatchableError, "Yaim: cannot grab Pointer")
  
  var grabKeyboardErr = XGrabKeyboard(dpy, overlay, 1, GrabModeAsync, GrabModeAsync, CurrentTime)
  var grabKeyboardTries = 0
  while( grabKeyboardErr != GrabSuccess and grabKeyboardTries < 10 ):
    1.sleep
    grabKeyboardErr = XGrabKeyboard(dpy, overlay, 1, GrabModeAsync, GrabModeAsync, CurrentTime)
    inc grabKeyboardTries
  
  if( grabKeyboardErr != GrabSuccess):
    discard XDestroyWindow(dpy, overlay)
    discard XCloseDisplay(dpy)
    raise newException(CatchableError, "Yaim: cannot grab Keyboard")

  var event: XEvent
  var x1, y1, x2, y2: cint
  var pressed = false
  var mapped = false # 枠線ウィンドウが表示されているかどうかのフラグ

  while true:
    discard XNextEvent(dpy, addr event)

    case event.theType
    of ButtonPress:
      if event.xbutton.button == Button1:
        x1 = event.xbutton.x
        y1 = event.xbutton.y
        pressed = true
      elif event.xbutton.button == Button3:
        discard XUngrabKeyboard(dpy, CurrentTime)
        discard XUngrabPointer(dpy, CurrentTime)
        discard XDestroyWindow(dpy, overlay)
        discard XCloseDisplay(dpy)
        raise newException(YaimCancel, "Yaim: selection cancelled")
      else:
        discard

    of MotionNotify:
      if pressed:
        x2 = event.xmotion.x
        y2 = event.xmotion.y

        let drawX = min(x1, x2)
        let drawY = min(y1, y2)

        let w = max(t, abs(x2 - x1).cuint)
        let h = max(t, abs(y2 - y1).cuint)

        # 上辺
        discard XMoveResizeWindow(dpy, borders[0], drawX, drawY, w, t)
        # 下辺
        discard XMoveResizeWindow(dpy, borders[1], drawX, drawY + h.cint - t.cint, w, t)
        # 左辺
        discard XMoveResizeWindow(dpy, borders[2], drawX, drawY, t, h)
        # 右辺
        discard XMoveResizeWindow(dpy, borders[3], drawX + w.cint - t.cint, drawY, t, h)

        if not mapped:
          for i in 0..3:
            discard XMapRaised(dpy, borders[i])
          mapped = true

        discard XFlush(dpy)

    of ButtonRelease:
      if pressed and (event.xbutton.button == Button1):
        x2 = event.xbutton.x
        y2 = event.xbutton.y
        break
      else:
        discard

    of KeyPress:
      let key = XLookupKeysym(addr event.xkey, 0)

      if key == XK_Escape:
        raise newException(YaimCancel, "Yaim: selection cancelled")

      if key == XK_q:
        raise newException(YaimCancel, "Yaim: selection cancelled")

      if key == XK_c and (event.xkey.state and ControlMask) != 0:
        raise newException(YaimCancel, "Yaim interrupted (SIGINT)")

    else:
      discard

  discard XUngrabPointer(dpy, CurrentTime)
  for i in 0..3:
    discard XDestroyWindow(dpy, borders[i])
  discard XDestroyWindow(dpy, overlay)
  discard XCloseDisplay(dpy)

  coords[0] = uint16(min(x1, x2))
  coords[1] = uint16(min(y1, y2))
  coords[2] = uint16(max(x1, x2))
  coords[3] = uint16(max(y1, y2))

  return coords
