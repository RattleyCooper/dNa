##
## dNa is an example of an archive file format.  It compresses files
## using the deflate algorithm and stores the files and some meta-data
## in a file.
## 
#


import nettystream
import strutils, os
import times
import zippy


const
  Information = "~dNa~"
  Version = 0.1f32


type 
  DnaFormatHeader* = object  # Header that is written to the beginning of the file.
    information*: string
    version*: float32
    totalFiles*: uint

  DnaFile* = ref object  # File name/data. Used to write/read files from the archive
    name*: string
    data*: seq[uint8]


proc writeDna*(fPaths: seq[string], outputFilePath: string = "collection.d.na") =
  ## Write files to the dNa archive format.
  #
  var dataStream = NettyStream()

  # Write file format header to data stream.
  let header = DnaFormatHeader(
    information: Information,
    version: Version,
    totalFiles: fPaths.len.uint
  )
  dataStream.write(header)

  # Create output file and write data stream's 
  # buffer to that file.
  var outputFile: File
  if not outputFile.open(outputFilePath, fmWrite):
    raise newException(Exception, "Could not open output file! " & outputFilePath)

  # Write files to data stream.
  for filePath in fPaths:
    var fPath = filePath.replace("\\", "/")
    var f: File
    if not f.open(fPath, fmRead):
      raise newException(Exception, "Could not open " & fPath)

    # Create a sequence of bytes and read the
    # the file into that sequence.
    let fSize = f.getFileSize()
    var fContents = newSeq[uint8](fSize)
    discard f.readBytes(fContents, 0, fSize)
    f.close()
    
    let fParts = fPath.split("/")
    let fName = fParts[^1]

    var compCont = fContents.compress(BestCompression, dfDeflate)
    # Create header for file contents and 
    # write those contents to the data stream.
    var dNa = DnaFile(
      name: fName,
      data: compCont
    )
    dataStream.write(dNa)
    outputFile.write(dataStream.getBuffer)
    dataStream.clear()
  outputFile.close()


proc readDna*(filePath: string, outDir: string = "") =
  ## Read a dNa file and extract the contents to the outDir.
  #
  var fPath = filepath.replace("\\", "/")
  # Open file and read contents
  var f: File
  var fContents: string
  if not f.open(fPath, fmRead):
    raise newException(Exception, "Could not open " & fPath)
  fContents = f.readAll()
  f.close()

  # Create data stream and add contents
  # of the file to the stream's buffer.
  var dataStream = NettyStream()
  dataStream.addToBuffer fContents
  dataStream.pos = 0  # Set buffer position to 0

  # Read the dNa Format header
  var header: DnaFormatHeader
  dataStream.read(header)

  # Check file header and error out if archive is unkown 
  if header.version > Version:
    let versionErrMsg = "The archive was created with a newer version of the dNa archiver.  Update to v" & $Version & " and try again."
    raise newException(Exception, versionErrMsg)
  if header.information != Information:
    let infoErrMsg = "Unknown archive type of " & header.information
    raise newException(Exception, infoErrMsg)
  
  # Extract files from the stream.
  var c = 0
  while not(dataStream.atEnd):
    # Read the dNa file header 
    var dNa: DnaFile
    dataStream.read(dNa)
    var oPath = outDir
    if not(oPath.endsWith("/")):
      oPath = oPath & "/"

    # Create output file and write bytes from
    # data stream.
    var outputFile: File
    if not outputFile.open(oPath & dNa.name, fmWrite):
      let errMsg = "Could not open file " & oPath & dNa.name
      raise newException(Exception, errMsg)
    let inflatedData = dNa.data.uncompress(dfDeflate)
    discard outputFile.writeBytes(inflatedData, 0, inflatedData.len)
    outputFile.close()
    c += 1
  
  if c < header.totalFiles.int:
    echo "Warning: Expected " & $header.totalFiles & " but only extracted " & $c


if isMainModule:
  # Get list of files
  let files = block:
    var res: seq[string]
    for kind, path in walkDir("testIn"):
      if kind != pcFile:
        continue
      res.add(path)
    res

  # write dNa archive
  let start = now()
  files.writeDna("collection.d.na")
  echo start - now()

  # Read from dNa archive and uncompress files.
  let readStart = now() 
  readDna("collection.d.na", "testOut")
  echo readStart - now()
