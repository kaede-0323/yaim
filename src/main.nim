import args, capture, coords

let opts: Options = parseArgs()

if opts.output.len == 0 and not opts.stdoutFlag:
  quit("Usage: --output <filename> xor --stdout")

let selCoords = getCoords()

captureScreen(selCoords, opts.windowId, opts.output, opts.fileType, opts.stdoutFlag)
