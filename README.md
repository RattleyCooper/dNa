# dNa (Deflate Nim Archive)

`.d.na` is a custom archive file format I pieced together when experimenting with data streams from the [`nettyrpc` library](https://github.com/beef331/nettyrpc).  It compresses files using [`zippy`](https://github.com/guzba/zippy), and the compressed files are added to the `.d.na` file.  

As of the date/time of this readme there is no validation mechanism to verify the integrity of the files that were compressed.  Other archive formats DO have this check, and it will be added here soon, but at this time nothing is validated.

## Why?

Mostly to learn more about the data stream used by `nettyrpc`, and constructing custom file formats.  I wouldn't rely on this format for anything serious.  Files are read/written in their entirety, so memory could be an issue and there is no file validation like you'd get with other archive formats.

### Example

```nim
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
```
