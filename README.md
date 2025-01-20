# Pathlib

This repository contains a library of pathlib implemented in Moonbit. 
This library provides methods for path handling, mainly referring to pathlib in **python** and std::path in **rust**. 
The procedure in this case is a pure function and does not involve system I/O.
It is compatible with both Windows and Unix paths.

## Structs

### WPath

A struct to provide Windows path.
What is different from Unix path is that it has a disk letter.

```moonbit
struct WPath {
  path : PurePath
  disk : Char
} derive(Eq)
```

### UPath

A struct to provide Unix path.

```moonbit
struct UPath {
  path : PurePath
} derive(Eq)
```

### Path

A enum to provide both Windows and Unix path.

```moonbit
pub(all) enum Path {
  WinPath(WPath)
  UnixPath(UPath)
} derive(Eq)
```

## Feature

### Methods

| Method | Description|
|--------|------------|
| `join` | Joins two paths together. |
| `parent` | Returns the parent path. |
| `to_path` | Converts an array of strings into a `PurePath` type by joining the strings in reverse order. |
| `unix_path` | Converts a path to its Unix representation. |
| `win_path` | Converts a path to its Windows representation. |
| `path` | Creates a Path instance from a string representation of a file system path. |
| `file_name` | Returns the final component of a path. |
| `file_stem` | Returns the first component of a path's filename before the first dot (.). |
| `file_prifix` | Returns the file prefix of a path, which is the part before the last dot (.). |
| `extension` | Returns the file extension of a path. |
| `is_absolute` | Checks if a path is absolute. |
| `is_relative` | Checks if a path is relative. |
| `has_root` | Checks if a path has a root. |
| `starts_with` | Checks if a path starts with another path. |
| `ends_with` | Checks if a path ends with another path. |
| `with_file_name` | Returns a new path with the specified filename. |
| `with_extension` | Returns a new path with the specified file extension. |
| `with_added_extension` | Returns a new path with the specified file extension added. |
| `strip_prefix` | Returns a new path with the specified prefix removed. |

## Usages

### pub fn Path::join(self : Path, b : Path) -> Path

Joins two paths together. The behavior depends on the type of the second.

#### Examples

```moonbit
let unix1 = UnixPath({ path: to_path(["home", "user"]) })
let unix2 = UnixPath({ path: to_path(["documents", "file.txt"]) })
let win = WinPath({ disk: 'C', path: to_path(["Users", "file.txt"]) })
unix_path(unix1.join(unix2)) |> println // /home/user/documents/file.txt
win_path(unix1.join(win)) |> println // C:\Users\file.txt
```

### pub fn Path::parent(self : Path) -> Path

Returns the parent directory component of the path.

#### Examples
```moonbit
let unix_path = UnixPath({ path: to_path(["home", "user", "file.txt"]) })
let win_path = WinPath({
  disk: 'C',
  path: to_path(["Users", "Documents", "file.txt"]),
})
unix_path.parent() |> println // /home/user
win_path.parent() |> println // C:\Users\Documents
```

### pub fn to_path(str : Array[String]) -> PurePath

Converts an array of strings into a `PurePath` type by joining the strings in reverse order.

#### Examples
```moonbit
let components = ["usr", "local", "bin"]
let path = to_path(components)
unix_path(UnixPath({ path })) |> println // /usr/local/bin
```

### pub fn Path::unix_path(self : Path) -> String

Converts a path to its Unix representation.

#### Examples
```moonbit
let path = UnixPath({ path: to_path(["home", "user", "file.txt"]) })
unix_path(path) |> println // /home/user/file.txt
```

### pub fn Path::win_path(self : Path) -> String

Converts a path to its Windows representation.

#### Examples
```moonbit
let win_path = WinPath({ disk: 'C', path: to_path(["Users", "Documents"]) })
win_path(win_path) |> println // C:\Users\Documents
```

### to_string

Provide win_path and unix_path to string.

#### Examples

```moonbit
let winpath = WinPath({ disk: 'C', path: to_path(["Users", "Documents"]) })
let unixpath = UnixPath({ path: to_path(["user", "local"]) })
println(winpath.to_string()) // C:\Users\Documents
println(unixpath.to_string()) // /user/local
```

### pub fn path(str : String) -> Path!@strconv.StrConvError

Creates a Path instance from a string representation of a file system path.

#### Examples
```moonbit
test "path" {
// Unix-style paths
path!("/usr/local/bin").to_string() |> println // /usr/local/bin
// Windows-style paths
path!("C:\\Windows\\System32").to_string() |> println // C:\Windows\System32
// Single component becomes Unix path
path!("file.txt").to_string() |> println // file.txt
}
```

### pub fn Path::file_name(self : Path) -> String

Returns the file name component of the path.

#### Examples
```moonbit
let unix_path = UnixPath({ path: to_path(["home", "user", "document.txt"]) })
let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.pdf"]) })
unix_path.file_name() |> println // document.txt
win_path.file_name() |> println // file.pdf
```

### pub fn Path::file_stem(self : Path) -> String

Returns the file stem (name without extension) of the path.

#### Examples
```moonbit
let unix_path = UnixPath({ path: to_path(["home", "user", "document.txt"]) })
let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.tar.gz"]) })
unix_path.file_stem() |> println // document
win_path.file_stem() |> println // file
```

### pub fn Path::file_prefix(self : Path) -> String

Returns the prefix of the file name in a path, including all except the last extension.

#### Examples
```moonbit
let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.tar.gz"]) })
let unix_path = UnixPath({ path: to_path(["home", "document.txt"]) })
win_path.file_prefix() |> println // C:\Users\file.tar
unix_path.file_prefix() |> println // /home/document
```

### pub fn Path::extension(self : Path) -> String

Returns the file extension of the path.

#### Examples
```moonbit
let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.tar.gz"]) })
let unix_path = UnixPath({ path: to_path(["home", "document.txt"]) })
let no_ext_path = UnixPath({ path: to_path(["home", "README"]) })
win_path.extension() |> println // gz
unix_path.extension() |> println // txt
no_ext_path.extension() |> println // ""
```

### pub fn Path::is_absolute(self : Path) -> Bool

Checks if the path is absolute.

#### Examples
```moonbit
// Unix path starting with root is absolute
let unix_path = UnixPath({ path: @immut/list.of(["", "usr", "bin"]) })
unix_path.is_absolute() |> println // true

// Windows path needs both valid disk and root to be absolute
let win_path = WinPath({ disk: 'C', path: @immut/list.of(["", "Windows"]) })
win_path.is_absolute() |> println // true
```

### pub fn Path::is_relative(self : Path) -> Bool

Checks if the path is relative.

#### Examples
```moonbit
// Unix relative path
let unix_path = UnixPath({ path: @immut/list.of(["usr", "bin"]) })
unix_path.is_relative() |> println // true
// Windows absolute path
let win_path = WinPath({ disk: 'C', path: @immut/list.of(["", "Windows"]) })
win_path.is_relative() |> println // false
```

### pub fn Path::has_root(self : Path) -> Bool

Checks if the path has a root component.

#### Examples
```moonbit
// Unix path with root
let unix_path = UnixPath({ path: @immut/list.of(["", "usr", "bin"]) })
unix_path.has_root() |> println // true
// Windows path without valid disk is not absolute, so no root
let win_path = WinPath({ disk: 'C', path: @immut/list.of(["Windows"]) })
win_path.has_root() |> println // false
```

### pub fn Path::starts_with(self : Path, base : Path) -> Bool

Checks if the path starts with a given base.

#### Examples
```moonbit
let base = UnixPath({ path: @immut/list.of(["usr", "bin"]) })
let path = UnixPath({ path: @immut/list.of(["usr", "bin", "python"]) })
path.starts_with(base) |> println // true

// Different path types never start with each other
let win_path = WinPath({ disk: 'C', path: @immut/list.of(["Users"]) })
win_path.starts_with(base) |> println // false
```

### pub fn Path::ends_with(self : Path, child : Path) -> Bool

Checks if the path ends with a given child.

#### Examples
```moonbit
// Unix path ending check
let path = UnixPath({ path: @immut/list.of(["usr", "local", "bin"]) })
let suffix = UnixPath({ path: @immut/list.of(["local", "bin"]) })
path.ends_with(suffix) |> println // true

// Windows path requires matching disk letter
let win_path = WinPath({
  disk: 'C',
  path: @immut/list.of(["Users", "Documents"]),
})
let wrong_disk = WinPath({ disk: 'D', path: @immut/list.of(["Documents"]) })
win_path.ends_with(wrong_disk) |> println // false
```

### pub fn Path::with_file_name(self : Path, name : String) -> Path

Returns a new path with the final component replaced by the specified name.

#### Examples
```moonbit
let unix_path = UnixPath({ path: to_path(["home", "user", "old.txt"]) })
unix_path.with_file_name("new.txt").unix_path() |> println // /home/user/new.txt
let win_path = WinPath({ disk: 'C', path: to_path(["Users", "old.txt"]) })
win_path.with_file_name("new.txt").win_path() |> println // C:\Users\new.txt
```

### pub fn Path::with_extension(self : Path, extension : String) -> Path

Replaces or removes the extension of the filename in a path.

#### Examples
```moonbit
let unix_path = UnixPath({ path: to_path(["home", "user", "file.txt"]) })
let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.tar.gz"]) })

// Replace extension
unix_path.with_extension("doc").unix_path() |> println // /home/user/file.doc

// Remove extension by passing empty string
win_path.with_extension("").win_path() |> println // C:\Users\file
```

### pub fn Path::with_added_extension(self : Path, extension : String) -> Path

Adds an extension to the filename in a path.

#### Examples
```moonbit
let path = UnixPath({ path: to_path(["home", "user", "file.txt"]) })
unix_path(path.with_added_extension("gz")) |> println // /home/user/file.txt.gz
```

### pub fn strip_prefix(self : Path, base : Path) -> Path!PrefixError

Removes a prefix from a path, returning the path relative to the prefix.

#### Examples
```moonbit
test "strip_prefix" {
  let path = UnixPath({ path: to_path(["usr", "local", "bin"]) })
  let prefix = UnixPath({ path: to_path(["usr", "local"]) })
  inspect!(strip_prefix!(path, prefix).unix_path(), content="/bin")
}
```

## License

This project is licensed under the Apache-2.0 License.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Contact

For any questions or suggestions, please contact [1279416582@qq.com].
