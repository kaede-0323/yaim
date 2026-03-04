# capture.nim
import strutils
import streams
import nimPNG
import x11/xlib

import coords

# img -> buffer コピー
proc copyXImageToBuffer(img: PXImage, width, height: int, buffer: var seq[byte]) =
  let src = cast[ptr UncheckedArray[uint32]](img.data)
  for y in 0..<height:
    for x in 0..<width:
      let pixel = src[y * width + x]
      let idx = (y * width + x) * 4
      buffer[idx + 0] = byte((pixel shr 16) and 0xFF) # R
      buffer[idx + 1] = byte((pixel shr 8) and 0xFF)  # G
      buffer[idx + 2] = byte(pixel and 0xFF)          # B
      buffer[idx + 3] = byte((pixel shr 24) and 0xFF) # A

proc captureScreen*(coords: Coord16, windowId: int, output: string, filetype: string, stdoutFlag: bool) =
  let dpy = XOpenDisplay(nil)
  if dpy.isNil:
    quit("Cannot open X display")

  let root = if windowId == -1: XDefaultRootWindow(dpy) else: TWindow(windowId)
  let width = int(coords[2] - coords[0])
  let height = int(coords[3] - coords[1])

  let img = XGetImage(dpy, root, cint(coords[0]), cint(coords[1]), cuint(width), cuint(height), culong(AllPlanes), ZPixmap)
  if img.isNil:
    discard XCloseDisplay(dpy)
    quit("Cannot capture image")

  var buffer = newSeq[byte](width * height * 4)
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

  discard XDestroyImage(img)
  discard XCloseDisplay(dpy)
