import lib/args,
       lib/capture, 
       lib/coords

when isMainModule:
  try:
    let opts: Options = parseArgs()

    if opts.output.len == 0 and not opts.stdoutFlag:
      stderr.writeLine("Usage: --output <filename> xor --stdout")
      quit(2)  # 引数エラー

    let selCoords = getCoords(opts.windowId)

    captureScreen(
      selCoords,
      opts.windowId,
      opts.output,
      opts.fileType,
      opts.stdoutFlag
    )

    quit(0)  # 正常終了

  except YaimCancel as e:
    stderr.writeLine(e.msg)
    quit(1)  # ユーザーキャンセル

  except CatchableError as e:
    stderr.writeLine("Yaim error: " & e.msg)
    quit(3)  # 実行時エラー
