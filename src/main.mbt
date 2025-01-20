///| 
typealias PurePath = @immut/list.T[String]

///|
struct WPath {
  path : PurePath
  disk : Char
} derive(Eq)

///|
struct UPath {
  path : PurePath
} derive(Eq)

///|
pub(all) enum Path {
  WinPath(WPath)
  UnixPath(UPath)
} derive(Eq)

///|
pub impl Show for Path with to_string(self) {
  match self {
    WinPath(_) => self.win_path()
    UnixPath(_) => self.unix_path()
  }
}

///|
pub impl Show for Path with output(self, logger) {
  match self {
    WinPath(_) => logger.write_object(self.win_path())
    UnixPath(_) => logger.write_object(self.unix_path())
  }
}

///|
fn Path::op_add(self : Path, b : Path) -> Path {
  self.join(b)
}

///|
/// Joins two paths together. The behavior depends on the type of the second
/// path:
///
/// * If the second path is a Windows path, the result will be a Windows path
/// with the disk letter from the second path.
/// * If the second path is a Unix path, the result will be a Unix path.
///
/// Parameters:
///
/// * `self` : The first path to join.
/// * `other` : The second path to join. When this is a Windows path, its disk
/// letter will be used in the result.
///
/// Returns a new path that concatenates the components of both paths in order.
///
/// Example:
///
/// ```moonbit
/// let unix1 = UnixPath({ path: to_path(["home", "user"]) })
/// let unix2 = UnixPath({ path: to_path(["documents", "file.txt"]) })
/// let win = WinPath({ disk: 'C', path: to_path(["Users", "file.txt"]) })
/// unix_path(unix1.join(unix2)) |> println // /home/user/documents/file.txt
/// win_path(unix1.join(win)) |> println // C:\Users\file.txt
/// ```
pub fn Path::join(self : Path, b : Path) -> Path {
  match b {
    WinPath(x) =>
      match self {
        WinPath(xs) => WinPath({ path: x.path.concat(xs.path), disk: x.disk })
        UnixPath(xs) => WinPath({ path: x.path.concat(xs.path), disk: x.disk })
      }
    UnixPath(x) =>
      match b {
        UnixPath(xs) => UnixPath({ path: x.path.concat(xs.path) })
        WinPath(xs) => UnixPath({ path: x.path.concat(xs.path) })
      }
  }
}

///|
/// Returns the parent directory component of the path.
/// For example, "foo/bar/baz.ext" will return "foo/bar".
///
/// Parameters:
///
/// * `self` : The path to get the parent directory from.
///
/// Returns a new path containing all components except the last one. If the path
/// is empty, returns an empty path.
///
/// Example:
///
/// ```moonbit
/// let unix_path = UnixPath({ path: to_path(["home", "user", "file.txt"]) })
/// let win_path = WinPath({
///   disk: 'C',
///   path: to_path(["Users", "Documents", "file.txt"]),
/// })
/// unix_path.parent() |> println // /home/user
/// win_path.parent() |> println // C:\Users\Documents
/// ```
pub fn Path::parent(self : Path) -> Path {
  match self {
    WinPath(x) =>
      WinPath({
        path: match x.path {
          Nil => Nil
          Cons(_, rest) => rest
        },
        disk: x.disk,
      })
    UnixPath(x) =>
      UnixPath({
        path: match x.path {
          Nil => Nil
          Cons(_, rest) => rest
        },
      })
  }
}

test "Patparent" {
  let unix_pth = UnixPath({ path: to_path(["home", "user", "file.txt"]) })
  let win_pth = WinPath({
    disk: 'C',
    path: to_path(["Users", "Documents", "file.txt"]),
  })
  inspect!(unix_pth.parent().unix_path(), content="/home/user")
  inspect!(win_pth.parent().win_path(), content="C:\\Users\\Documents")
}

///|
/// Converts an array of strings into a `PurePath` type by joining the strings in
/// reverse order.
///
/// Parameters:
///
/// * `components` : An array of strings representing path components.
///
/// Returns an immutable list (`PurePath`) containing the path components in
/// reverse order.
///
/// Example:
///
/// ```moonbit
/// let components = ["usr", "local", "bin"]
/// let path = to_path(components)
/// unix_path(UnixPath({ path })) |> println // /usr/local/bin
/// ```
pub fn to_path(str : Array[String]) -> PurePath {
  loop 0, PurePath::Nil {
    i, acc => {
      if i == str.length() {
        break acc
      }
      continue i + 1, Cons(str[i], acc)
    }
  }
}

///|
/// Converts a path to its Unix representation. If the path is a Unix path,
/// returns a string representation with forward slashes as separators. If the
/// path is a Windows path, returns an empty string.
///
/// Parameters:
///
/// * `path` : The path to be converted. Can be either a Unix path or a Windows
/// path.
///
/// Returns a string representation of the path using Unix conventions (forward
/// slashes as separators), or an empty string if the input is a Windows path.
///
/// Example:
///
/// ```moonbit
/// let path = UnixPath({ path: to_path(["home", "user", "file.txt"]) })
/// unix_path(path) |> println // /home/user/file.txt
/// 
/// // Windows paths are converted to empty string
/// let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.txt"]) })
/// unix_path(win_path) |> println // ""
/// ```
pub fn Path::unix_path(self : Path) -> String {
  match self {
    UnixPath(x) =>
      loop x.path, "" {
        Nil, str => break str
        Cons(str, rest), other => continue rest, "/\{str}\{other}"
      }
    _ => ""
  }
}

///|
/// Converts a path to its Windows representation. If the path is a Windows path,
/// returns a string representation with backslashes as separators and a disk
/// letter prefix. If the path is a Unix path, returns an empty string.
///
/// Parameters:
///
/// * `path` : The path to be converted. Can be either a Unix path or a Windows
/// path.
///
/// Returns a string representation of the path using Windows conventions
/// (backslashes as separators and disk letter prefix), or an empty string if the
/// input is a Unix path.
///
/// Example:
///
/// ```moonbit
/// // Windows path with disk letter
/// let win_path = WinPath({ disk: 'C', path: to_path(["Users", "Documents"]) })
/// win_path(win_path) |> println // C:\Users\Documents
/// 
/// // Unix path returns empty string
/// let unix_path = UnixPath({ path: to_path(["usr", "local"]) })
/// win_path(unix_path) |> println // ""
/// ```
pub fn Path::win_path(self : Path) -> String {
  match self {
    WinPath(x) =>
      loop x.path, "" {
        Nil, str =>
          match x.disk {
            '?' => break str.substring(start=1)
            _ => break "\{x.disk}:\{str}"
          }
        Cons(str, rest), other => continue rest, "\\\{str}\{other}"
      }
    _ => ""
  }
}

///|
/// Creates a Path instance from a string representation of a file system path.
/// Automatically detects and creates the appropriate path type (Unix or Windows)
/// based on the path format:
///
/// * Creates a Unix path if the string contains no disk letter and uses forward
/// slashes (/) as separators
/// * Creates a Windows path if the string contains a disk letter (e.g., "C:") or
/// uses backslashes (\\) as separators
/// * Creates a Unix path with a single component if the string contains no
/// separators
///
/// Parameters:
///
/// * `path_str` : A string representing a file system path. For Windows paths,
/// can include an optional disk letter prefix (e.g., "C:"). Can use either
/// forward slashes (/) or backslashes (\\) as separators.
///
/// Returns a Path value representing the parsed path, which will be either a
/// UnixPath or WinPath depending on the format of the input string.
///
/// Throws a `StrConvError` if the input string is empty.
///
/// Example:
///
/// ```moonbit
/// test "path" {
/// // Unix-style paths
/// path!("/usr/local/bin").to_string() |> println // /usr/local/bin
/// // Windows-style paths
/// path!("C:\\Windows\\System32").to_string() |> println // C:\Windows\System32
/// // Single component becomes Unix path
/// path!("file.txt").to_string() |> println // file.txt
/// }
/// ```
pub fn path(str : String) -> Path!@strconv.StrConvError {
  // Check: if the path is empty
  if str == "" {
    raise @strconv.StrConvError("Empty path")
  }
  // Check: dont have any slash
  if str.index_of("/") == -1 && str.index_of("\\") == -1 {
    return UnixPath({ path: to_path([str]) })
    // Check: unix path separator only (no disk letter)
  } else if str.index_of("/") != -1 && str.index_of(":") == -1 {
    let parts = str.split("/")
    let filtered = parts.filter(fn(x) { x != "" }).to_array()
    return UnixPath({ path: to_path(filtered) })
  } else {
    // Check: disk letter
    let mut disk = '?'
    let mut str_copy = str
    if str.length() >= 2 && str[1] == ':' {
      disk = str[0].to_string().to_upper()[0]
      str_copy = str.substring(start=2)
    }
    // Check: path separator
    let parts = match str_copy.index_of("/") {
      -1 => str_copy.split("\\")
      _ => str_copy.split("/")
    }
    let filtered = parts.filter(fn(x) { x != "" }).to_array()
    println(filtered)
    return WinPath({ path: to_path(filtered), disk })
  }
}

test "match path" {
  let arr = ["abc", "cde", "333"]
  let arr2 = ["abcc", "cded", "3333"]
  let l : Path = WinPath({ path: to_path(arr), disk: 'D' })
  let ll : Path = WinPath({ path: to_path(arr2), disk: 'D' })
  println(l.win_path())
  println(ll.parent().win_path())
  println((l + ll).parent().win_path())
  println(
    (match path?("k:/333/cde/abc") {
      Ok(x) => x
      Err(_) => panic()
    }).win_path(),
  )
}

///|
/// Returns the final component of a path. If the path is empty, returns an empty
/// string.
///
/// Parameters:
///
/// * `path` : The path to extract the file name from. Can be either a Windows
/// path or a Unix path.
///
/// Returns the file name as a string. For example, for path "/foo/bar/baz.txt",
/// returns "baz.txt".
///
/// Example:
///
/// ```moonbit
/// let unix_path = UnixPath({ path: to_path(["home", "user", "document.txt"]) })
/// let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.pdf"]) })
/// unix_path.file_name() |> println // document.txt
/// win_path.file_name() |> println // file.pdf
/// ```
pub fn Path::file_name(self : Path) -> String {
  match self {
    WinPath(x) =>
      match x.path {
        Nil => ""
        Cons(file, _) => file
      }
    UnixPath(x) =>
      match x.path {
        Nil => ""
        Cons(file, _) => file
      }
  }
}

///|
/// Returns the first component of a path's filename before the first dot (.). If
/// there is no dot in the filename, returns the entire filename. If the path is
/// empty, returns an empty string.
///
/// Parameters:
///
/// * `self`: The path to extract the file stem from. Can be either a Windows
/// path or a Unix path.
///
/// Returns the file stem as a string. For example, for path "/foo/bar/baz.txt",
/// returns "baz"; for path "/foo/bar/baz.tar.gz", returns "baz".
///
/// Example:
///
/// ```moonbit
/// let unix_path = UnixPath({ path: to_path(["home", "user", "document.txt"]) })
/// let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.tar.gz"]) })
/// unix_path.file_stem() |> println // document
/// win_path.file_stem() |> println // file
/// ```
pub fn Path::file_stem(self : Path) -> String {
  match self {
    WinPath(x) =>
      match x.path {
        Nil => ""
        Cons(file, _) => {
          let idx = file.index_of(".")
          if idx == -1 {
            file
          } else {
            file.substring(start=0, end=idx)
          }
        }
      }
    UnixPath(x) =>
      match x.path {
        Nil => ""
        Cons(file, _) => {
          let idx = file.index_of(".")
          if idx == -1 {
            file
          } else {
            file.substring(start=0, end=idx)
          }
        }
      }
  }
}

///|
/// Returns the prefix of the file name in a path, including all except the last
/// extension. For example, for file name "file.tar.gz", returns "file.tar". If
/// there is no extension, returns the entire file name. If the path is empty,
/// returns an empty string.
///
/// Parameters:
///
/// * `path` : The path to extract the file prefix from. Can be either a Windows
/// path or a Unix path.
///
/// Returns a string representing the file prefix. For a file name with multiple
/// extensions (like "file.tar.gz"), includes all components except the last
/// extension.
///
/// Example:
///
/// ```moonbit
/// let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.tar.gz"]) })
/// let unix_path = UnixPath({ path: to_path(["home", "document.txt"]) })
/// win_path.file_prefix() |> println // C:\Users\file.tar
/// unix_path.file_prefix() |> println // /home/document
/// ```
pub fn Path::file_prefix(self : Path) -> String {
  match self {
    WinPath(x) =>
      match x.path {
        Nil => ""
        Cons(file, _) => {
          let idx = file.last_index_of(".")
          if idx == -1 {
            file
          } else {
            file.substring(start=0, end=idx)
          }
        }
      }
    UnixPath(x) =>
      match x.path {
        Nil => ""
        Cons(file, _) => {
          let idx = file.last_index_of(".")
          if idx == -1 {
            file
          } else {
            file.substring(start=0, end=idx)
          }
        }
      }
  }
}

///|
/// Returns the file extension of the path. For a path containing a filename with
/// multiple dots, returns the substring after the last dot. If there is no dot
/// in the filename or if the path is empty, returns an empty string.
///
/// Parameters:
///
/// * `self` : The path to get the extension from. Can be either a Windows path
/// or a Unix path.
///
/// Returns the file extension as a string, without the leading dot.
///
/// Example:
///
/// ```moonbit
/// let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.tar.gz"]) })
/// let unix_path = UnixPath({ path: to_path(["home", "document.txt"]) })
/// let no_ext_path = UnixPath({ path: to_path(["home", "README"]) })
/// win_path.extension() |> println // gz
/// unix_path.extension() |> println // txt
/// no_ext_path.extension() |> println // ""
/// ```
pub fn Path::extension(self : Path) -> String {
  match self {
    WinPath(x) =>
      match x.path {
        Nil => ""
        Cons(file, _) => {
          let idx = file.last_index_of(".")
          if idx == -1 {
            ""
          } else {
            file.substring(start=idx + 1)
          }
        }
      }
    UnixPath(x) =>
      match x.path {
        Nil => ""
        Cons(file, _) => {
          let idx = file.last_index_of(".")
          if idx == -1 {
            ""
          } else {
            file.substring(start=idx + 1)
          }
        }
      }
  }
}

test "path slice" {
  let arr = ["abc", "cde", "333.tar.gz"]
  let arr2 = ["abc", "cde", "333"]
  let l : Path = WinPath({ path: to_path(arr), disk: 'D' })
  let ll : Path = WinPath({ path: to_path(arr2), disk: 'D' })
  inspect!(l.file_name(), content="333.tar.gz")
  inspect!(l.file_stem(), content="333")
  inspect!(l.file_prefix(), content="333.tar")
  inspect!(l.extension(), content="gz")
  inspect!(ll.file_name(), content="333")
  inspect!(ll.file_stem(), content="333")
  inspect!(ll.extension(), content="")
}

///|
/// Determines if a path is absolute.
///
/// For Unix paths, returns true if the path starts with a root directory (/).
/// For Windows paths, returns true if the path has both a valid disk letter (not
/// '?') and starts with a root directory.
///
/// Parameters:
///
/// * `path` : The path to check. Can be either a Unix path or a Windows path.
///
/// Returns `true` if the path is absolute, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// // Unix path starting with root is absolute
/// let unix_path = UnixPath({ path: @immut/list.of(["", "usr", "bin"]) })
/// unix_path.is_absolute() |> println // true
/// 
/// // Windows path needs both valid disk and root to be absolute
/// let win_path = WinPath({ disk: 'C', path: @immut/list.of(["", "Windows"]) })
/// win_path.is_absolute() |> println // true
/// ```
pub fn Path::is_absolute(self : Path) -> Bool {
  match self {
    UnixPath(x) =>
      match x.path {
        Nil => false
        Cons(first, _) => first == ""
      }
    WinPath(x) =>
      // Check if it has a valid disk letter (not '?') and starts with root
      match x.path {
        Nil => false
        Cons(first, _) => x.disk != '?' && first == ""
      }
  }
}

///|
/// Determines whether a path is relative by checking if it is not absolute.
///
/// For Unix paths, a path is relative if it does not start with a root directory
/// (/).
/// For Windows paths, a path is relative if it either lacks a valid disk letter
/// or does not start with a root directory.
///
/// Parameters:
///
/// * `self` : The path to check. Can be either a Unix path or a Windows path.
///
/// Returns `true` if the path is relative, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// // Unix relative path
/// let unix_path = UnixPath({ path: @immut/list.of(["usr", "bin"]) })
/// unix_path.is_relative() |> println // true
/// 
/// // Windows absolute path
/// let win_path = WinPath({ disk: 'C', path: @immut/list.of(["", "Windows"]) })
/// win_path.is_relative() |> println // false
/// ```
pub fn Path::is_relative(self : Path) -> Bool {
  return not(self.is_absolute())
}

test "is_absolute/unix" {
  // Unix absolute paths start with root
  inspect!(
    UnixPath({ path: @immut/list.of(["", "usr", "bin"]) }).is_absolute(),
    content="true",
  )
  // Unix relative paths don't start with root
  inspect!(
    UnixPath({ path: @immut/list.of(["usr", "bin"]) }).is_absolute(),
    content="false",
  )
  // Empty Unix path is not absolute
  inspect!(
    UnixPath({ path: @immut/list.T::Nil }).is_absolute(),
    content="false",
  )
}

test "is_absolute/windows" {
  // Windows absolute paths need both valid disk and root
  inspect!(
    WinPath({ path: @immut/list.of(["", "Windows"]), disk: 'C' }).is_absolute(),
    content="true",
  )
  // Windows paths without valid disk letter are not absolute
  inspect!(
    WinPath({ path: @immut/list.of(["", "temp"]), disk: '?' }).is_absolute(),
    content="false",
  )
  // Windows paths without root are not absolute, even with disk
  inspect!(
    WinPath({ path: @immut/list.of(["temp"]), disk: 'C' }).is_absolute(),
    content="false",
  )
  // Empty Windows path is not absolute
  inspect!(
    WinPath({ path: @immut/list.T::Nil, disk: 'C' }).is_absolute(),
    content="false",
  )
}

///|
/// Returns true if the Path has a root.
/// On Unix, a path has a root if it begins with /.
/// On Windows, a path has a root if it:
/// - has no prefix and begins with a separator, e.g., \windows
/// - has a prefix followed by a separator, e.g., c:\windows but not c:windows
/// - has any non-disk prefix, e.g., \\server\share
pub fn Path::has_root(self : Path) -> Bool {
  match self {
    UnixPath(x) =>
      match x.path {
        Nil => false
        Cons(first, _) => first == ""
      }
    WinPath(x) =>
      match x.path {
        Nil => false
        Cons(first, _) => first == ""
      }
  }
}

test "has_root/unix" {
  // Unix path with root
  inspect!(
    UnixPath({ path: @immut/list.of(["", "usr", "bin"]) }).has_root(),
    content="true",
  )
  // Unix path without root
  inspect!(
    UnixPath({ path: @immut/list.of(["usr", "bin"]) }).has_root(),
    content="false",
  )
  // Empty Unix path
  inspect!(UnixPath({ path: @immut/list.T::Nil }).has_root(), content="false")
}

test "has_root/windows" {
  // Windows path with root (disk letter followed by root)
  inspect!(
    WinPath({ path: @immut/list.of(["", "Windows"]), disk: 'C' }).has_root(),
    content="true",
  )
  // Windows path without root but with disk
  inspect!(
    WinPath({ path: @immut/list.of(["Windows"]), disk: 'C' }).has_root(),
    content="false",
  )
  // Empty Windows path
  inspect!(
    WinPath({ path: @immut/list.T::Nil, disk: 'C' }).has_root(),
    content="false",
  )
}

test "has_root/special_cases" {
  // Path with only root
  inspect!(UnixPath({ path: @immut/list.of([""]) }).has_root(), content="true")
  inspect!(
    WinPath({ path: @immut/list.of([""]), disk: 'C' }).has_root(),
    content="true",
  )
  // Path with invalid disk letter should still work if it has root
  inspect!(
    WinPath({ path: @immut/list.of(["", "temp"]), disk: '?' }).has_root(),
    content="true",
  )
}

///|
/// Determines if a path begins with a given base path. For Windows paths, both
/// the disk letter and path components must match. For Unix paths, only the path
/// components need to match.
///
/// Parameters:
///
/// * `self` : The path to check.
/// * `base` : The potential prefix path.
///
/// Returns `true` if `base` is a prefix of `self`, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let base = UnixPath({ path: @immut/list.of(["usr", "bin"]) })
/// let path = UnixPath({ path: @immut/list.of(["usr", "bin", "python"]) })
/// path.starts_with(base) |> println // true
/// 
/// // Different path types never start with each other
/// let win_path = WinPath({ disk: 'C', path: @immut/list.of(["Users"]) })
/// win_path.starts_with(base) |> println // false
/// ```
pub fn Path::starts_with(self : Path, base : Path) -> Bool {
  match (self, base) {
    (WinPath(x), WinPath(y)) =>
      // For Windows paths, check disk letter and path components
      if x.disk != y.disk {
        false
      } else {
        // Convert paths to lists for comparison
        let self_parts = x.path.rev()
        let base_parts = y.path.rev()
        // Compare each component
        loop (self_parts, base_parts) {
          (_, Nil) => true // base is exhausted, it's a prefix
          (Nil, _) => false // self is exhausted but base isn't
          (Cons(s, srest), Cons(b, brest)) =>
            if s != b {
              false
            } else {
              continue (srest, brest)
            }
        }
      }
    (UnixPath(x), UnixPath(y)) => {
      // For Unix paths, just check path components
      let self_parts = x.path.rev()
      let base_parts = y.path.rev()
      // Compare each component
      loop (self_parts, base_parts) {
        (_, Nil) => true // base is exhausted, it's a prefix
        (Nil, _) => false // self is exhausted but base isn't
        (Cons(s, srest), Cons(b, brest)) =>
          if s != b {
            false
          } else {
            continue (srest, brest)
          }
      }
    }
    _ => false // Different path types can't be prefixes of each other
  }
}

test "starts_with/windows" {
  // Test Windows paths with same disk and matching prefix
  let base = WinPath({ disk: 'C', path: to_path(["Windows"]) })
  let base2 = WinPath({ disk: 'C', path: to_path(["Windows", "System32"]) })
  let path = WinPath({ disk: 'C', path: to_path(["Windows", "System32"]) })
  inspect!(path.starts_with(base), content="true")
  inspect!(path.starts_with(base2), content="true")

  // Test Windows paths with different disks but same path
  let other_disk = WinPath({ disk: 'D', path: to_path(["Windows"]) })
  inspect!(path.starts_with(other_disk), content="false")
}

test "starts_with/unix" {
  // Test Unix paths with matching prefix
  let base = UnixPath({ path: to_path(["usr", "bin"]) })
  let base2 = UnixPath({ path: to_path(["bin"]) })
  let path = UnixPath({ path: to_path(["usr", "bin", "python"]) })
  inspect!(path.starts_with(base), content="true")
  inspect!(path.starts_with(base2), content="false")

  // Test Unix paths with different prefixes
  let different = UnixPath({ path: to_path(["usr", "local"]) })
  inspect!(path.starts_with(different), content="false")
}

test "starts_with/cross_type" {
  // Test mixing Windows and Unix paths
  let win = WinPath({ disk: 'C', path: to_path(["Users"]) })
  let unix = UnixPath({ path: to_path(["Users"]) })
  inspect!(win.starts_with(unix), content="false")
  inspect!(unix.starts_with(win), content="false")

  // Test empty paths
  let empty_win = WinPath({ disk: 'C', path: @immut/list.T::Nil })
  let empty_unix = UnixPath({ path: @immut/list.T::Nil })
  inspect!(empty_win.starts_with(empty_unix), content="false")
}

///|
/// Determines if a path ends with a given suffix path. For Windows paths, both
/// paths must have the same disk letter and matching trailing components. For
/// Unix paths, only the path components are compared.
///
/// Parameters:
///
/// * `path` : The path to check.
/// * `suffix` : The potential suffix path.
///
/// Returns `true` if `suffix` matches the end components of `path`, `false`
/// otherwise. Returns `false` if the paths are of different types (Unix vs
/// Windows) or if `suffix` is longer than `path`.
///
/// Example:
///
/// ```moonbit
/// // Unix path ending check
/// let path = UnixPath({ path: @immut/list.of(["usr", "local", "bin"]) })
/// let suffix = UnixPath({ path: @immut/list.of(["local", "bin"]) })
/// path.ends_with(suffix) |> println // true
/// 
/// // Windows path requires matching disk letter
/// let win_path = WinPath({
///   disk: 'C',
///   path: @immut/list.of(["Users", "Documents"]),
/// })
/// let wrong_disk = WinPath({ disk: 'D', path: @immut/list.of(["Documents"]) })
/// win_path.ends_with(wrong_disk) |> println // false
/// ```
pub fn Path::ends_with(self : Path, child : Path) -> Bool {
  match (self, child) {
    (WinPath(x), WinPath(y)) =>
      // For Windows paths, check disk letter and path components
      if x.disk != y.disk {
        false
      } else {
        // Convert paths to lists for comparison
        let self_parts = x.path
        let child_parts = y.path
        // Get lengths for comparison
        let self_len = loop self_parts, 0 {
          Nil, acc => break acc
          Cons(_, rest), acc => continue rest, acc + 1
        }
        let child_len = loop child_parts, 0 {
          Nil, acc => break acc
          Cons(_, rest), acc => continue rest, acc + 1
        }
        if child_len > self_len {
          false
        } else {
          // Skip the non-matching prefix of self
          let skip = self_len - child_len
          let mut trimmed = self_parts
          for i = 0; i < skip; i = i + 1 {
            match trimmed {
              Cons(_, rest) => trimmed = rest
              Nil => ()
            }
          }
          // Compare remaining components
          loop (trimmed, child_parts) {
            (Nil, Nil) => true
            (Cons(s, srest), Cons(c, crest)) =>
              if s != c {
                false
              } else {
                continue (srest, crest)
              }
            _ => false
          }
        }
      }
    (UnixPath(x), UnixPath(y)) => {
      // For Unix paths, just check path components
      let self_parts = x.path
      let child_parts = y.path
      // Get lengths for comparison
      let self_len = loop self_parts, 0 {
        Nil, acc => break acc
        Cons(_, rest), acc => continue rest, acc + 1
      }
      let child_len = loop child_parts, 0 {
        Nil, acc => break acc
        Cons(_, rest), acc => continue rest, acc + 1
      }
      if child_len > self_len {
        false
      } else {
        // Skip the non-matching prefix of self
        let skip = self_len - child_len
        let mut trimmed = self_parts
        for i = 0; i < skip; i = i + 1 {
          match trimmed {
            Cons(_, rest) => trimmed = rest
            Nil => ()
          }
        }
        // Compare remaining components
        loop (trimmed, child_parts) {
          (Nil, Nil) => true
          (Cons(s, srest), Cons(c, crest)) =>
            if s != c {
              false
            } else {
              continue (srest, crest)
            }
          _ => false
        }
      }
    }
    _ => false // Different path types can't be suffixes of each other
  }
}

test "ends_with/windows" {
  // Test full path suffix matching
  let path = WinPath({
    disk: 'C',
    path: @immut/list.of(["Users", "Documents", "file.txt"]),
  })
  let suffix = WinPath({
    disk: 'C',
    path: @immut/list.of(["Documents", "file.txt"]),
  })
  inspect!(path.ends_with(suffix), content="true")

  // Test different disk letters
  let diff_disk = WinPath({
    disk: 'D',
    path: @immut/list.of(["Documents", "file.txt"]),
  })
  inspect!(path.ends_with(diff_disk), content="false")

  // Test empty paths
  let empty = WinPath({ disk: 'C', path: @immut/list.T::Nil })
  inspect!(path.ends_with(empty), content="true")
}

test "ends_with/unix" {
  // Test path suffix matching with root
  let path = UnixPath({ path: @immut/list.of(["", "usr", "local", "bin"]) })
  let suffix = UnixPath({ path: @immut/list.of(["local", "bin"]) })
  inspect!(path.ends_with(suffix), content="true")

  // Test longer suffix than path
  let longer = UnixPath({ path: @immut/list.of(["opt", "usr", "local", "bin"]) })
  inspect!(path.ends_with(longer), content="false")

  // Test empty suffix
  let empty = UnixPath({ path: @immut/list.T::Nil })
  inspect!(path.ends_with(empty), content="true")
}

test "ends_with/cross_type" {
  let win_path = WinPath({
    disk: 'C',
    path: @immut/list.of(["Users", "Documents"]),
  })
  let unix_path = UnixPath({ path: @immut/list.of(["Users", "Documents"]) })

  // Test mixing path types
  inspect!(win_path.ends_with(unix_path), content="false")
  inspect!(unix_path.ends_with(win_path), content="false")
}

///|
/// Returns a new path with the final component replaced by the specified name.
/// If the path is empty, creates a new path with a single component containing
/// the given name.
///
/// Parameters:
///
/// * `self` : The original path. Can be either a Unix path or a Windows path.
/// * `name` : The new file name to replace the final component with.
///
/// Returns a new path of the same type as the input (Unix or Windows) with the
/// final component replaced by the given name.
///
/// Example:
///
/// ```moonbit
/// let unix_path = UnixPath({ path: to_path(["home", "user", "old.txt"]) })
/// unix_path.with_file_name("new.txt").unix_path() |> println // /home/user/new.txt
/// let win_path = WinPath({ disk: 'C', path: to_path(["Users", "old.txt"]) })
/// win_path.with_file_name("new.txt").win_path() |> println // C:\Users\new.txt
/// ```
pub fn Path::with_file_name(self : Path, name : String) -> Path {
  match self {
    WinPath(x) =>
      match x.path {
        Nil => WinPath({ path: @immut/list.of([name]), disk: x.disk })
        Cons(_, rest) => WinPath({ path: Cons(name, rest), disk: x.disk })
      }
    UnixPath(x) =>
      match x.path {
        Nil => UnixPath({ path: @immut/list.of([name]) })
        Cons(_, rest) => UnixPath({ path: Cons(name, rest) })
      }
  }
}

test "with_file_name/windows" {
  // Normal case with multiple components
  let winpath = WinPath({
    disk: 'C',
    path: to_path(["Users", "Documents", "old.txt"]),
  })
  inspect!(
    winpath.with_file_name("new.txt").win_path(),
    content="C:\\Users\\Documents\\new.txt",
  )

  // Empty path case
  let empty_win = WinPath({ disk: 'D', path: @immut/list.T::Nil })
  inspect!(
    empty_win.with_file_name("file.txt").win_path(),
    content="D:\\file.txt",
  )
}

test "with_file_name/unix" {
  // Normal case with multiple components
  let unixpath = UnixPath({ path: to_path(["home", "user", "doc.txt"]) })
  inspect!(
    unixpath.with_file_name("new.txt").unix_path(),
    content="/home/user/new.txt",
  )

  // Empty path case
  let empty_unix = UnixPath({ path: @immut/list.T::Nil })
  inspect!(
    empty_unix.with_file_name("file.txt").unix_path(),
    content="/file.txt",
  )
}

test "with_file_name/special_chars" {
  // Test with special characters in filename
  let path = WinPath({
    disk: 'C',
    path: to_path(["Users", "Documents", "old.txt"]),
  })
  inspect!(
    path.with_file_name("file with spaces.txt").win_path(),
    content="C:\\Users\\Documents\\file with spaces.txt",
  )
  inspect!(
    path.with_file_name("file#1.txt").win_path(),
    content="C:\\Users\\Documents\\file#1.txt",
  )
}

///|
/// Replaces or removes the extension of the filename in a path. If the path has
/// no filename component, returns the original path unchanged.
///
/// Parameters:
///
/// * `self` : The path whose extension is to be modified.
/// * `extension` : The new extension to set, without the leading dot. If empty,
/// removes any existing extension.
///
/// Returns a new path with the modified extension.
///
/// Example:
///
/// ```moonbit
/// let unix_path = UnixPath({ path: to_path(["home", "user", "file.txt"]) })
/// let win_path = WinPath({ disk: 'C', path: to_path(["Users", "file.tar.gz"]) })
/// 
/// // Replace extension
/// unix_path.with_extension("doc").unix_path() |> println // /home/user/file.doc
/// 
/// // Remove extension by passing empty string
/// win_path.with_extension("").win_path() |> println // C:\Users\file
/// ```
pub fn Path::with_extension(self : Path, extension : String) -> Path {
  match self {
    WinPath(x) =>
      match x.path {
        Nil => self
        Cons(file, rest) => {
          let idx = file.last_index_of(".")
          if idx == -1 {
            // No extension - add new one if provided
            if extension == "" {
              self
            } else {
              WinPath({ path: Cons("\{file}.\{extension}", rest), disk: x.disk })
            }
          } else {
            // Has extension - replace with new one
            let base = file.substring(start=0, end=idx)
            if extension == "" {
              WinPath({ path: Cons(base, rest), disk: x.disk })
            } else {
              WinPath({ path: Cons("\{base}.\{extension}", rest), disk: x.disk })
            }
          }
        }
      }
    UnixPath(x) =>
      match x.path {
        Nil => self
        Cons(file, rest) => {
          let idx = file.last_index_of(".")
          if idx == -1 {
            // No extension - add new one if provided
            if extension == "" {
              self
            } else {
              UnixPath({ path: Cons("\{file}.\{extension}", rest) })
            }
          } else {
            // Has extension - replace with new one
            let base = file.substring(start=0, end=idx)
            if extension == "" {
              UnixPath({ path: Cons(base, rest) })
            } else {
              UnixPath({ path: Cons("\{base}.\{extension}", rest) })
            }
          }
        }
      }
  }
}

test "with_extension/basic" {
  // Test basic extension replacement for both Windows and Unix paths
  let winpath = WinPath({ disk: 'C', path: to_path(["Users", "file.txt"]) })
  let unixpath = UnixPath({ path: to_path(["home", "file.txt"]) })
  inspect!(
    winpath.with_extension("doc").win_path(),
    content="C:\\Users\\file.doc",
  )
  inspect!(unixpath.with_extension("doc").unix_path(), content="/home/file.doc")
}

test "with_extension/empty" {
  // Test with empty extension and no extension
  let winpath = WinPath({ disk: 'C', path: to_path(["Users", "file.txt"]) })
  let win_no_ext = WinPath({ disk: 'C', path: to_path(["Users", "file"]) })
  inspect!(winpath.with_extension("").win_path(), content="C:\\Users\\file")
  inspect!(win_no_ext.with_extension("").win_path(), content="C:\\Users\\file")
}

test "with_extension/multiple_dots" {
  // Test with multiple dots in filename
  let winpath = WinPath({ disk: 'C', path: to_path(["Users", "file.tar.gz"]) })
  let unixpath = UnixPath({ path: to_path(["home", "file.tar.gz"]) })
  inspect!(
    winpath.with_extension("xz").win_path(),
    content="C:\\Users\\file.tar.xz",
  )
  inspect!(
    unixpath.with_extension("xz").unix_path(),
    content="/home/file.tar.xz",
  )
}

///|
/// Adds an extension to the filename in a path. This function preserves any
/// existing extensions, unlike `with_extension` which replaces them. If the
/// extension is empty, returns the original path unchanged.
///
/// Parameters:
///
/// * `self` : The path to modify.
/// * `extension` : The extension to add to the filename, without the leading
/// dot.
///
/// Returns a new path with the added extension.
///
/// Example:
///
/// ```moonbit
/// let path = UnixPath({ path: to_path(["home", "user", "file.txt"]) })
/// unix_path(path.with_added_extension("gz")) |> println // /home/user/file.txt.gz
/// ```
pub fn Path::with_added_extension(self : Path, extension : String) -> Path {
  match self {
    WinPath(x) =>
      match x.path {
        Nil => self
        Cons(file, rest) =>
          if extension == "" {
            self
          } else {
            WinPath({ path: Cons("\{file}.\{extension}", rest), disk: x.disk })
          }
      }
    UnixPath(x) =>
      match x.path {
        Nil => self
        Cons(file, rest) =>
          if extension == "" {
            self
          } else {
            UnixPath({ path: Cons("\{file}.\{extension}", rest) })
          }
      }
  }
}

test "with_added_extension/basic" {
  // Test basic extension addition for both Windows and Unix paths
  let winpath = WinPath({ disk: 'C', path: to_path(["Users", "file"]) })
  let unixpath = UnixPath({ path: to_path(["home", "file"]) })
  inspect!(
    winpath.with_added_extension("txt").win_path(),
    content="C:\\Users\\file.txt",
  )
  inspect!(
    unixpath.with_added_extension("txt").unix_path(),
    content="/home/file.txt",
  )
}

test "with_added_extension/empty" {
  // Test with empty extension
  let winpath = WinPath({ disk: 'C', path: to_path(["Users", "file"]) })
  let unixpath = UnixPath({ path: to_path(["home", "file"]) })

  // Empty extension should return original path
  inspect!(
    winpath.with_added_extension("").win_path(),
    content="C:\\Users\\file",
  )
  inspect!(unixpath.with_added_extension("").unix_path(), content="/home/file")
}

test "with_added_extension/existing_extension" {
  // Test adding extension to files that already have extensions
  let winpath = WinPath({ disk: 'C', path: to_path(["Users", "file.txt"]) })
  let unixpath = UnixPath({ path: to_path(["home", "file.txt"]) })
  inspect!(
    winpath.with_added_extension("gz").win_path(),
    content="C:\\Users\\file.txt.gz",
  )
  inspect!(
    unixpath.with_added_extension("gz").unix_path(),
    content="/home/file.txt.gz",
  )
}

///|
type! PrefixError String

///|
/// Removes a prefix from a path, returning the path relative to the prefix. The
/// operation preserves the path type and, for Windows paths, the disk letter of
/// the original path.
///
/// Parameters:
///
/// * `path` : The path from which to remove the prefix.
/// * `prefix` : The prefix path to remove. Must be of the same type (Unix or
/// Windows) as the path.
///
/// Returns a new path with the prefix removed.
///
/// Throws a `PrefixError` if:
///
/// * The prefix is not actually a prefix of the path
/// * The path and prefix are of different types (Unix vs Windows)
///
/// Example:
///
/// ```moonbit
/// test "strip_prefix" {
///   let path = UnixPath({ path: to_path(["usr", "local", "bin"]) })
///   let prefix = UnixPath({ path: to_path(["usr", "local"]) })
///   inspect!(strip_prefix!(path, prefix).unix_path(), content="/bin")
/// }
/// ```
pub fn strip_prefix(self : Path, base : Path) -> Path!PrefixError {
  // First check if base is a prefix
  if not(self.starts_with(base)) {
    raise PrefixError("Base path is not a prefix of the path")
  }
  match (self, base) {
    (WinPath(x), WinPath(y)) => {
      // Get lengths
      let xx = x.path.rev()
      let yy = y.path.rev()
      let self_len = loop xx, 0 {
        Nil, acc => break acc
        Cons(_, rest), acc => continue rest, acc + 1
      }
      let base_len = loop yy, 0 {
        Nil, acc => break acc
        Cons(_, rest), acc => continue rest, acc + 1
      }

      // Skip prefix components
      let mut remaining = xx
      for i = 0; i < base_len; i = i + 1 {
        match remaining {
          Cons(_, rest) => remaining = rest
          Nil => ()
        }
      }

      // Return new path with same disk letter
      WinPath({ path: remaining.rev(), disk: x.disk })
    }
    (UnixPath(x), UnixPath(y)) => {
      // Get lengths 
      let xx = x.path.rev()
      let yy = y.path.rev()
      let self_len = loop xx, 0 {
        Nil, acc => break acc
        Cons(_, rest), acc => continue rest, acc + 1
      }
      let base_len = loop yy, 0 {
        Nil, acc => break acc
        Cons(_, rest), acc => continue rest, acc + 1
      }

      // Skip prefix components
      let mut remaining = xx
      for i = 0; i < base_len; i = i + 1 {
        match remaining {
          Cons(_, rest) => remaining = rest
          Nil => ()
        }
      }

      // Return new Unix path
      UnixPath({ path: remaining.rev() })
    }
    _ => raise PrefixError("Cannot strip prefix of different path types")
  }
}

test "strip_prefix/unix" {
  // Test stripping Unix paths
  let path = UnixPath({ path: to_path(["usr", "local", "bin"]) })
  let base = UnixPath({ path: to_path(["usr", "local"]) })
  //println(strip_prefix!(path, base).unix_path())
  inspect!(strip_prefix!(path, base).unix_path(), content="/bin")

  // Test with empty base path
  let empty_base = UnixPath({ path: @immut/list.T::Nil })
  //println(strip_prefix!(path, empty_base).unix_path())
  inspect!(
    strip_prefix!(path, empty_base).unix_path(),
    content="/usr/local/bin",
  )
}

test "strip_prefix/windows" {
  // Test stripping Windows paths with same disk
  let path = WinPath({ disk: 'C', path: to_path(["Users", "Admin", "Desktop"]) })
  let base = WinPath({ disk: 'C', path: to_path(["Users", "Admin"]) })
  inspect!(strip_prefix!(path, base).win_path(), content="C:\\Desktop")
}

test "panic strip_prefix/invalid" {
  // Test different path types
  let unix = UnixPath({ path: to_path(["usr", "bin"]) })
  let win = WinPath({ disk: 'C', path: to_path(["Windows"]) })

  // Should panic when trying to strip different path types
  let _ = strip_prefix!(unix, win)

  // Should panic when base is not a prefix
  let non_prefix = UnixPath({ path: to_path(["var"]) })
  let _ = strip_prefix!(unix, non_prefix)

}
