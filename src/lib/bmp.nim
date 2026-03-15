proc put16le(f: File, v: uint16) =
  var b = [byte(v and 0xff), byte((v shr 8) and 0xff)]
  discard f.writeBuffer(addr b[0], 2)

proc put32le(f: File, v: uint32) =
  var b = [
    byte(v and 0xff),
    byte((v shr 8) and 0xff),
    byte((v shr 16) and 0xff),
    byte((v shr 24) and 0xff)
  ]
  discard f.writeBuffer(addr b[0], 4)

proc saveBMP*(output: string, buffer: seq[byte], w, h: int): bool =
  stderr.writeLine("rgba.len = " & $buffer.len) 
  stderr.writeLine("excepted = " & $(w * h * 4)) 

  var f: File
  var ok: bool
  if not (open(f, output, fmWrite)):
    ok = false
    

  let pixelBytes = w * h * 4
  let fileSize = 54 + pixelBytes

  # --- BMP HEADER ---
  f.write("BM")
  put32le(f, uint32(fileSize))
  put32le(f, 0'u32)
  put32le(f, 54'u32)

  # --- DIB HEADER ---
  put32le(f, 40'u32)
  put32le(f, uint32(w))
  put32le(f, uint32(h))
  put16le(f, 1)
  put16le(f, 32)
  put32le(f, 0)
  put32le(f, uint32(pixelBytes))
  put32le(f, 0)
  put32le(f, 0)
  put32le(f, 0)
  put32le(f, 0)

  for y in countdown(h-1, 0):
    for x in 0..<w:
      let i = (y*w + x) * 4
      var px = [
        buffer[i+2], # B
        buffer[i+1], # G
        buffer[i],   # R
        buffer[i+3]  # A
      ]
      discard f.writeBuffer(addr px[0], 4)

  f.close()
  ok = true

  return ok
