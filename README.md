# Pathlib

This repository contains a library of pathlib implemented in Moonbit. 
This library provides methods for path handling, mainly referring to `pathlib` in `python` and `std::path` in `rust`. 
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

### PurePath

```moonbit
typealias PurePath = @immut/list.T[String]
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
| `relative_to` | Returns a new path relative to the specified base path. 
| `ends_with` | Checks if a path ends with another path. |
| `with_file_name` | Returns a new path with the specified filename. |
| `with_extension` | Returns a new path with the specified file extension. |
| `with_added_extension` | Returns a new path with the specified file extension added. |
| `strip_prefix` | Returns a new path with the specified prefix removed. |
| `drive` | Returns the drive component of a path. |
| `root` | Returns the root component of a path. |
| `anchor` | Returns the anchor component of a path. |
| `as_posix` | Returns a string representation of the path using POSIX-style separators(forward slashes). |
| `parents` | Returns an array containing all parent components of a path in descending order.|

## Usages

### pub fn Path::join(self : Path, b : Path) -> Path

Joins two paths together. The behavior depends on the type of the second.

#### Examples

```moonbit
let unix1 = UnixPath({ path: to_path(["/home", "user"]) })
let unix2 = UnixPath({ path: to_path(["/documents", "file.txt"]) })
let win = WinPath({ disk: 'C', path: to_path(["\\Users", "file.txt"]) })
unix_path(unix1.join(unix2)) |> println // /home/user/documents/file.txt
win_path(unix1.join(win)) |> println // C:\Users\file.txt
```

### pub fn Path::parent(self : Path) -> Path

Returns the parent directory component of the path.

#### Examples
```moonbit
let unix_path = UnixPath({ path: to_path(["/home", "user", "file.txt"]) })
let win_path = WinPath({
  disk: 'C',
  path: to_path(["\\Users", "Documents", "file.txt"]),
})
unix_path.parent() |> println // /home/user
win_path.parent() |> println // C:\Users\Documents
```

### pub fn to_path(str : Array[String]) -> PurePath

Converts an array of strings into a `PurePath` type by joining the strings in reverse order.

#### Examples
```moonbit
let components = ["/usr", "local", "bin"]
let path = to_path(components)
unix_path(UnixPath({ path })) |> println // /usr/local/bin
```

Spurious slashes and single dots are collapsed, but double dots ('..') and leading double slashes ('//') are not.

```moonbit
test "to_path" {
  let components = ["/usr", "local/bin", "./test/../path", "t.py"]
  let path = to_path(components)
  println(UnixPath({path}).unix_path())// /usr/local/bin/test/../path/t.py
}
```

### pub fn Path::unix_path(self : Path) -> String

Converts a path to its Unix representation.

#### Examples
```moonbit
let path = UnixPath({ path: to_path(["/home", "user", "file.txt"]) })
unix_path(path) |> println // /home/user/file.txt
```

### pub fn Path::win_path(self : Path) -> String

Converts a path to its Windows representation.

#### Examples
```moonbit
let win_path = WinPath({ disk: 'C', path: to_path(["\\Users", "Documents"]) })
win_path(win_path) |> println // C:\Users\Documents
```

### to_string

Provide win_path and unix_path to string.

#### Examples

```moonbit
let winpath = WinPath({ disk: 'C', path: to_path(["\\Users", "Documents"]) })
let unixpath = UnixPath({ path: to_path(["/user", "local"]) })
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
let unix_path = UnixPath({ path: to_path(["/home", "user", "document.txt"]) })
let win_path = WinPath({ disk: 'C', path: to_path(["\\Users", "file.pdf"]) })
unix_path.file_name() |> println // document.txt
win_path.file_name() |> println // file.pdf
```

### pub fn Path::file_stem(self : Path) -> String

Returns the file stem (name without extension) of the path.

#### Examples
```moonbit
let unix_path = UnixPath({ path: to_path(["/home", "user", "document.txt"]) })
let win_path = WinPath({ disk: 'C', path: to_path(["\\Users", "file.tar.gz"]) })
unix_path.file_stem() |> println // document
win_path.file_stem() |> println // file
```

### pub fn Path::file_prefix(self : Path) -> String

Returns the prefix of the file name in a path, including all except the last extension.

#### Examples
```moonbit
let win_path = WinPath({ disk: 'C', path: to_path(["\\Users", "file.tar.gz"]) })
let unix_path = UnixPath({ path: to_path(["/home", "document.txt"]) })
win_path.file_prefix() |> println // C:\Users\file.tar
unix_path.file_prefix() |> println // /home/document
```

### pub fn Path::extension(self : Path) -> String

Returns the file extension of the path.

#### Examples
```moonbit
let win_path = WinPath({ disk: 'C', path: to_path(["\\Users", "file.tar.gz"]) })
let unix_path = UnixPath({ path: to_path(["/home", "document.txt"]) })
let no_ext_path = UnixPath({ path: to_path(["/home", "README"]) })
win_path.extension() |> println // gz
unix_path.extension() |> println // txt
no_ext_path.extension() |> println // ""
```

### pub fn Path::is_absolute(self : Path) -> Bool

Checks if the path is absolute.

In unix, it's equal to `has_root`.
In Windows, it's equal to `has_root` and `disk != "?"`, or it's a `UNC` path.
A `UNC` path is a path that starts with `\\` or `//`.

#### Examples
```moonbit
// Unix path starting with root is absolute
let unix_path = UnixPath({ path: to_path(["/usr", "bin"]) })
unix_path.is_absolute() |> println // true

// Windows path needs both valid disk and root to be absolute
let win_path = WinPath({ disk: 'C', path: to_path(["\\Windows"]) })
win_path.is_absolute() |> println // true

// When Windows path is a UNC Path
let win_path2 = WinPath({ disk: '?', path: to_path(["//some/share"]) })
win_path2.is_absolute() |> println // true
```

### pub fn Path::is_relative(self : Path) -> Bool

Checks if the path is relative.

#### Examples
```moonbit
// Unix relative path
let unix_path = UnixPath({ path: to_path(["usr", "bin"]) })
unix_path.is_relative() |> println // true
// Windows absolute path
let win_path = WinPath({ disk: 'C', path: to_path(["Windows"]) })
win_path.is_relative() |> println // true
```

### pub fn Path::has_root(self : Path) -> Bool

Checks if the path has a root component.
If a Windows path is a `UNC` path, it's considered to have a root.

#### Examples
```moonbit
// Unix path with root
let unix_path = UnixPath({ path: to_path(["/usr", "bin"]) })
unix_path.has_root() |> println // true
// Windows path without valid disk is not absolute, so no root
let win_path = WinPath({ disk: 'C', path: to_path(["Windows"]) })
win_path.has_root() |> println // false
```

### pub fn Path::starts_with(self : Path, base : Path) -> Bool

Checks if the path starts with a given base.

#### Examples
```moonbit
let base = UnixPath({ path: to_path(["usr", "bin"]) })
let path = UnixPath({ path: to_path(["usr", "bin", "python"]) })
path.starts_with(base) |> println // true

// Different path types never start with each other
let win_path = WinPath({ disk: 'C', path: to_path(["Users"]) })
win_path.starts_with(base) |> println // false
```

### pub fn Path::relative_to(self : Path, other : Path) -> Path!PrefixError

Calculates a path relative to another base path. For Windows paths, both
paths must share the same disk letter. For Unix paths, no additional
constraints are required besides path compatibility.

Throws a `PrefixError` if:

* The paths are of different types (Unix vs Windows)
* For Windows paths, the disk letters are different
* The base path is not a prefix of the source path

#### Examples
```moonbit
test "Path::relative_to" {
  let source = UnixPath({ path: to_path(["usr", "local", "bin"]) })
  let base = UnixPath({ path: to_path(["usr", "local"]) })
  inspect!(source.relative_to!(base).unix_path(), content="bin")
}
```

### pub fn Path::ends_with(self : Path, child : Path) -> Bool

Checks if the path ends with a given child.

#### Examples
```moonbit
// Unix path ending check
let path = UnixPath({ path: to_path(["usr", "local", "bin"]) })
let suffix = UnixPath({ path: to_path(["local", "bin"]) })
path.ends_with(suffix) |> println // true

// Windows path requires matching disk letter
let win_path = WinPath({
  disk: 'C',
  path: to_path(["Users", "Documents"]),
})
let wrong_disk = WinPath({ disk: 'D', path: to_path(["Documents"]) })
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
let unix_path = UnixPath({ path: to_path(["/home", "user", "file.txt"]) })
let win_path = WinPath({ disk: 'C', path: to_path(["\\Users", "file.tar.gz"]) })

// Replace extension
unix_path.with_extension("doc").unix_path() |> println // /home/user/file.doc

// Remove extension by passing empty string
win_path.with_extension("").win_path() |> println // C:\Users\file
```

### pub fn Path::with_added_extension(self : Path, extension : String) -> Path

Adds an extension to the filename in a path.

#### Examples
```moonbit
let path = UnixPath({ path: to_path(["/home", "user", "file.txt"]) })
unix_path(path.with_added_extension("gz")) |> println // /home/user/file.txt.gz
```

### pub fn Path::strip_prefix(self : Path, base : Path) -> Path!PrefixError

Removes a prefix from a path, returning the path relative to the prefix.

#### Examples
```moonbit
test "strip_prefix" {
  let path = UnixPath({ path: to_path(["/usr", "local", "bin"]) })
  let prefix = UnixPath({ path: to_path(["/usr", "local"]) })
  inspect!(strip_prefix!(path, prefix).unix_path(), content="bin")
}
```

### pub fn Path::drive(self : Path) -> String

Returns the drive identifier of a path, which includes:

* For Windows paths with a disk letter: returns the disk letter followed by a
colon (e.g., "C:")
* For Windows UNC (Universal Naming Convention) paths: returns the host and
share components (e.g., "\\\\server\\share")
* For Unix paths or paths without drive information: returns an empty string

#### Examples
```moonbit
test "drive" {
  let win_path = WinPath({ disk: 'C', path: to_path(["Users", "Documents"]) })
  let unc_path = WinPath({
    disk: '?',
    path: to_path(["\\\\server\\share\\path"]),
  })
  let unix_path = UnixPath({ path: to_path(["/usr", "local"]) })
  inspect!(win_path.drive(), content="C:")
  inspect!(unc_path.drive(), content="\\\\\\\\server\\\\share") //  "\\\\server\\share"
  inspect!(unix_path.drive(), content="")
}
```

### pub fn Path::root(self : Path) -> String

Returns the root directory component of a path.

For Windows paths:

* Returns "\\" for paths with a root directory (starting with "/" or "")
* Returns "\\" for UNC (Universal Naming Convention) paths (starting with
"//" or "\\")
* Returns an empty string for paths without a root directory

For Unix paths:

* Returns "/" for paths with a root directory (starting with "/")
* Returns an empty string for paths without a root directory

#### Examples
```moonbit
test "root" {
  // Windows paths
  let win_rooted = WinPath({ disk: 'C', path: to_path(["\\Windows"]) })
  let win_unc = WinPath({ disk: '?', path: to_path(["\\\\server\\share"]) })
  inspect!(win_rooted.root(), content="\\\\")
  inspect!(win_unc.root(), content="\\\\")

  // Unix paths
  let unix_rooted = UnixPath({ path: to_path(["/usr"]) })
  inspect!(unix_rooted.root(), content="/")
}
```

### pub fn Path::anchor(self : Path) -> String

Returns the anchor component of a path, which is the combination of the drive
and root components.

#### Examples
```moonbit
let win_path = WinPath({ disk: 'C', path: to_path(["\\Windows"]) })
let unix_path = UnixPath({ path: to_path(["/usr"]) })
win_path.anchor() |> println // C:\\
unix_path.anchor() |> println // /
```

### pub fn Path::as_posix(self : Path) -> String

Returns a string representation of the path using POSIX-style separators
(forward slashes). For Windows paths, converts backslashes to forward slashes
and changes the format of UNC paths and drive letters to follow POSIX
conventions.

#### Examples
```moonbit
test "as_posix" {
  let win_path = WinPath({ disk: 'C', path: to_path(["Windows\\System32"]) })
  let unc_path = WinPath({ disk: '?', path: to_path(["\\\\server\\share"]) })
  inspect!(win_path.as_posix(), content="C:/Windows/System32")
  inspect!(unc_path.as_posix(), content="//server/share")
}
```

### pub fn Path::parents(self : Path) -> Array[Path]

Returns an array containing all parent components of a path in descending
order (i.e., from the most specific to the most general).

For example, for a path "/a/b/c", returns \["/a/b", "/a"].

#### Examples
```moonbit
test "Path::parents" {
  let unix_path = UnixPath({ path: to_path(["/usr", "local", "bin"]) })
  let parents = unix_path.parents()
  inspect!(parents[0].unix_path(), content="/usr/local")
  inspect!(parents[1].unix_path(), content="/usr")
}
```

## TODO

`full_match` and `match`: these methods should refer to [Pattern language](https://docs.python.org/3.13/library/pathlib.html#pathlib-pattern-language).

## License

This project is licensed under the Apache-2.0 License.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Contact

For any questions or suggestions, please contact [1279416582@qq.com].
