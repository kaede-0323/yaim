{.compile: "ximage_wrapper.c".}
{.passL: "-lX11".}

type
  XImage* = object
  Display* = object
  Window* = int64

proc wrap_getXImageData*(img: ptr XImage): ptr uint32 {.cdecl, importc.}
proc wrap_XOpenDisplay*(name: cstring): ptr Display {.cdecl, importc.}
proc wrap_XDefaultRootWindow*(dpy: ptr Display): Window {.cdecl, importc.}
proc wrap_XGetImage*(dpy: ptr Display, win: Window, x, y: int, width, height: uint, plane_mask, format: int): ptr XImage {.cdecl, importc.}
proc wrap_XDestroyImage*(img: ptr XImage): int {.cdecl, importc.}
proc wrap_XCloseDisplay*(dpy: ptr Display): int {.cdecl, importc.}
