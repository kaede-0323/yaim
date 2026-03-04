#coords.nim
import x11/xlib

type
  Coord16* = array[4, uint16] # [左上X, 左上Y, 右上X, 右上Y]

proc getCoords*(): Coord16 =
  var coords: Coord16

  let dpy = XOpenDisplay(nil)
  if dpy.isNil:
    quit("Cannot open X Display")

  let root = XDefaultRootWindow(dpy)

  if XGrabPointer(dpy, root, 1, ButtonPressMask or ButtonReleaseMask or PointerMotionMask, GrabModeAsync, GrabModeAsync, 0, 0, CurrentTime) != GrabSuccess:
    discard XCloseDisplay(dpy)
    quit("Cannot grab pointer")

  var event: TXEvent
  var x1, y1, x2, y2: cint
  var pressed = false

  while true:
    XNextEvent(dpy, addr event)

    case event.theType
    of ButtonPress:
      x1 = event.xbutton.x
      y1 = event.xbutton.y
      pressed = true
    of ButtonRelease:
      if pressed:
        x2 = event.xbutton.x
        y2 = event.xbutton.y
        break
    else:
      discard

  discard XUngrabPointer(dpy, CurrentTime)
  discard XCloseDisplay(dpy)

  coords[0] = uint16(min(x1, x2))
  coords[1] = uint16(min(y1, y2))
  coords[2] = uint16(max(x1, x2))
  coords[3] = uint16(max(y1, y2))

  return coords
