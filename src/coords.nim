#coords.nim
{.passC: "-lX11".}

import math
import ximage_wrapper

type
  Coord16* = array[4, uint16] # [左上X, 左上Y, 右上X, 右上Y]

type
  XEvent* = array[24, int]
  GC* = object
  Bool* = int

proc XGrabPointer(dpy: ptr Display, grab_window: Window, ownerEvents: Bool,
                 event_mask: int, pointer_mode, keyboard_mode: int,
                 confine_to: Window, cursor: Window, time: int): int {.cdecl, importc.}
proc XUngrabPointer(dpy: ptr Display, time: int): int {.cdecl, importc.}
proc XNextEvent(dpy: ptr Display, event: ptr XEvent) {.cdecl, importc.}
proc XDrawRectangle(dpy: ptr Display, win: Window, gc: ptr GC, x, y, width, height: uint) {.cdecl, importc.}

const
  ButtonPressMask = 1 shl 2
  ButtonReleaseMask = 1 shl 3
  PointerMotionMask = 1 shl 6
  ExposureMask = 1 shl 15

proc XCreateGC(dpy: ptr Display, win: Window, valuemask: int, values: pointer): ptr GC {.cdecl, importc.}

proc getCoords*(): Coord16 =
  var coords: Coord16

  let dpy = wrap_XOpenDisplay(nil)
  if dpy == nil: quit("Cannot open X Display")
  let root = wrap_XDefaultRootWindow(dpy)
  let gc = XCreateGC(dpy, root, 0, cast[pointer](nil))

  if XGrabPointer(dpy, root, 1, ButtonPressMask or ButtonReleaseMask or PointerMotionMask, 1, 1, 0, 0, 0) != 0:
    discard wrap_XCloseDisplay(dpy)
    quit("Cannot grab pointer")

  var event: XEvent
  var x1, y1, x2, y2: int
  var lastX = -1
  var lastY = -1
  var lastW = 0
  var lastH = 0

  while true:
    XNextEvent(dpy, addr event)
    if (event[0] and ButtonPressMask)== ButtonPressMask: # Button Press
      x1 = event.xbutton.x
      y1 = event.xbutton.y
      break

  while true:
    XNextEvent(dpy, addr event)
    case event[0] and (ButtonPressMask or ButtonReleaseMask)
    of ButtonPressMask:
      x1 = event.xbutton.x
      y1 = event.xbutton.y
      if lastW > 0 and lastH > 0:
        XDrawRectangle(dpy, root, gc, uint(lastX), uint(lastY), uint(lastW), uint(lastH))

      let w = abs(x2 - x1)
      let h = abs(y2 - y1)
      let drawX = min(x1, x2)
      let drawY = min(y1, y2)
      XDrawRectangle(dpy, root, gc, uint(drawX), uint(drawY), uint(w), uint(h))
      lastX = drawX
      lastY = drawY
      lastW = w
      lastH = h
    of ButtonReleaseMask:
      x2 = event[1]
      y2 = event[2]
      break
    else:
      break

  discard XUngrabPointer(dpy, 0)
  discard wrap_XCloseDisplay(dpy)

  coords[0] = uint16(min(x1, x2))
  coords[1] = uint16(min(y1, y2))
  coords[2] = uint16(max(x1, x2))
  coords[3] = uint16(max(y1, y2))
  
  return coords
