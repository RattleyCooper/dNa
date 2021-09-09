# dNa (Deflate Nim Archive)

`.d.na` is a custom archive format(similar to zip or tar) I pieced together when experimenting with the `NettyStream` type from the [`nettyrpc` library](https://github.com/beef331/nettyrpc).  dNa compresses files using [`zippy`](https://github.com/guzba/zippy), and the compressed files are added to a `.d.na` archive.

As of the date/time of this readme there is no validation mechanism to verify the integrity of the files that were compressed.  Other archive formats DO perform this check, and it will be added here soon, but at this time nothing is validated.

## Why?

Mostly to learn more about the data stream used by `nettyrpc`, and constructing custom file formats. I took a naive approach, so I expect there are some differences to how archive file formats work and how dNa works. At this time I wouldn't rely on this archive format for anything serious.  Files are read/written in their entirety, so memory could be an issue and there is no file validation like you'd get with other archive formats. This archive structure is also VERY similar to zip so at this point it's not doing anything new.

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
files.writeDna("collection.d.na")

# Read from dNa archive and uncompress files.
readDna("collection.d.na", "testOut")
```
