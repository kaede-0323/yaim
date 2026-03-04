# args.nim
import os
import strutils

type
  Options* = object
    output*: string
    stdoutFlag*: bool
    windowId*: int
    fileType*: string

proc parseArgs*(): Options =
  var opts = Options(output: "", stdoutFlag: false, windowId: -1, fileType: "png")
  var args = commandLineParams()  # paramStr/paramCountの代わりに配列で取得
  for i, arg in args.pairs:
    case arg
    of "-o", "--output":
      if i + 1 < args.len:
        opts.output = args[i+1]
    of "--stdout":
      opts.stdoutFlag = true
    of "-t", "--type":
      if i + 1 < args.len:
        opts.fileType = args[i+1]
    of "-w", "--window":
      if i + 1 < args.len:
        opts.windowId = parseInt(args[i+1])
  return opts
