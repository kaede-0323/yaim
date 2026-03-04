# capture.nim
{.passC: "-lX11".}
import strutils
import streams, math
import nimPNG
import ximage_wrapper

type
  Coord16* = array[4, uint16]

# img -> buffer コピー
proc copyXImageToBuffer(img: ptr XImage, width, height: int, buffer: var seq[byte]) =
  var src = wrap_getXImageData(img)
  # ptr uint32 を可変長配列として扱う
  let arrPtr = cast[ptr array[0..0, uint32]](src)
  for y in 0..<height:
    for x in 0..<width:
      let pixel = arrPtr[y*width + x]  # これでポインタ先の値を直接取得
      let idx = (y*width + x)*4
      buffer[idx + 0] = byte((pixel shr 16) and 0xFF) # R
      buffer[idx + 1] = byte((pixel shr 8) and 0xFF)  # G
      buffer[idx + 2] = byte(pixel and 0xFF)           # B
      buffer[idx + 3] = byte((pixel shr 24) and 0xFF) # A

proc captureScreen*(coords: Coord16, windowId: int, output: string, filetype: string, stdoutFlag: bool) =
  {.passC: "-lX11".}

  let dpy = wrap_XOpenDisplay(nil)
  if dpy == nil: quit("Cannot open X display")

  let root = if windowId == -1: wrap_XDefaultRootWindow(dpy) else: Window(windowId)
  let width = int(coords[2] - coords[0])
  let height = int(coords[3] - coords[1])

  let img = wrap_XGetImage(dpy, root, int(coords[0]), int(coords[1]), uint(width), uint(height), int(0xFFFFFFFF'u32), 2) # ZPixmap
  if img == nil:
    discard wrap_XCloseDisplay(dpy)
    quit("Cannot capture image")

  var buffer = newSeq[byte](width*height*4)
  # img -> Buffer
  copyXImageToBuffer(img, width, height, buffer)


  case fileType.toLower()
  of "png":
    if output.len > 0:
      discard savePNG32(output, buffer, width, height)
    elif stdoutFlag:
      let pngObj = encodePNG32(buffer, width, height)
      let s = StringStream()
      s.writeData(pngObj.pixels[0].addr, pngObj.pixels.len)
  of "raw":
    if output.len > 0:
      let f = open(output, fmWrite)
      f.write(buffer)
      f.close()
    elif stdoutFlag:
      stdout.write(buffer)
  else:
    quit("Unsupported file type: " & fileType)

  discard wrap_XDestroyImage(img)
  discard wrap_XCloseDisplay(dpy)
