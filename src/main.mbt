///| 
typealias PurePath = @immut/list.T[String]

///|
struct WPath {
  path : PurePath
  disk : Char
}

///|
struct UPath {
  path : PurePath
}

///|
pub(all) enum Path {
  WinPath(WPath)
  UnixPath(UPath)
}

///|
fn op_add(self : Path, b : Path) -> Path {
  join(self, b)
}

///|
pub fn join(self : Path, b : Path) -> Path {
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
pub fn parent(self : Path) -> Path {
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

///|
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
pub fn unix_path(path : Path) -> String {
  match path {
    UnixPath(x) =>
      loop x.path, "" {
        Nil, str => break str
        Cons(str, rest), other => continue rest, "/\{str}\{other}"
      }
    _ => ""
  }
}

///|
pub fn win_path(path : Path) -> String {
  match path {
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
  println(win_path(l))
  println(win_path(ll.parent()))
  println(win_path((l + ll).parent()))
  println(
    win_path(
      match path?("k:/333/cde/abc") {
        Ok(x) => x
        Err(_) => panic()
      },
    ),
  )
}

///|
pub fn file_name(self : Path) -> String {
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
pub fn file_stem(self : Path) -> String {
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
pub fn file_prefix(self : Path) -> String {
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
pub fn extension(self : Path) -> String {
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
/// Returns true if the Path is absolute, i.e., if it is independent of the current directory.
/// On Unix, a path is absolute if it starts with the root, 
/// so is_absolute and has_root are equivalent.
/// On Windows, a path is absolute if it has a prefix and starts with the root: c:\windows is absolute, 
/// while c:temp and \temp are not.
pub fn is_absolute(self : Path) -> Bool {
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
pub fn is_relative(self : Path) -> Bool {
  return not(self.is_absolute())
}

test "is_absolute/unix" {
  // Unix absolute paths start with root
  inspect!(
    UnixPath({ path: @immut/list.T::of(["", "usr", "bin"]) }).is_absolute(),
    content="true",
  )
  // Unix relative paths don't start with root
  inspect!(
    UnixPath({ path: @immut/list.T::of(["usr", "bin"]) }).is_absolute(),
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
    WinPath({ path: @immut/list.T::of(["", "Windows"]), disk: 'C' }).is_absolute(),
    content="true",
  )
  // Windows paths without valid disk letter are not absolute
  inspect!(
    WinPath({ path: @immut/list.T::of(["", "temp"]), disk: '?' }).is_absolute(),
    content="false",
  )
  // Windows paths without root are not absolute, even with disk
  inspect!(
    WinPath({ path: @immut/list.T::of(["temp"]), disk: 'C' }).is_absolute(),
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
pub fn has_root(self : Path) -> Bool {
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
    UnixPath({ path: @immut/list.T::of(["", "usr", "bin"]) }).has_root(),
    content="true",
  )
  // Unix path without root
  inspect!(
    UnixPath({ path: @immut/list.T::of(["usr", "bin"]) }).has_root(),
    content="false",
  )
  // Empty Unix path
  inspect!(UnixPath({ path: @immut/list.T::Nil }).has_root(), content="false")
}

test "has_root/windows" {
  // Windows path with root (disk letter followed by root)
  inspect!(
    WinPath({ path: @immut/list.T::of(["", "Windows"]), disk: 'C' }).has_root(),
    content="true",
  )
  // Windows path without root but with disk
  inspect!(
    WinPath({ path: @immut/list.T::of(["Windows"]), disk: 'C' }).has_root(),
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
  inspect!(
    UnixPath({ path: @immut/list.T::of([""]) }).has_root(),
    content="true",
  )
  inspect!(
    WinPath({ path: @immut/list.T::of([""]), disk: 'C' }).has_root(),
    content="true",
  )
  // Path with invalid disk letter should still work if it has root
  inspect!(
    WinPath({ path: @immut/list.T::of(["", "temp"]), disk: '?' }).has_root(),
    content="true",
  )
}

///|
/// Determines whether base is a prefix of self.
/// Only considers whole path components to match.
pub fn starts_with(self : Path, base : Path) -> Bool {
  match (self, base) {
    (WinPath(x), WinPath(y)) =>
      // For Windows paths, check disk letter and path components
      if x.disk != y.disk {
        false
      } else {
        // Convert paths to lists for comparison
        let self_parts = x.path
        let base_parts = y.path

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
      let self_parts = x.path
      let base_parts = y.path

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
  let base = WinPath({ disk: 'C', path: @immut/list.T::of(["Windows"]) })
  let base2 = WinPath({
    disk: 'C',
    path: @immut/list.T::of(["Windows", "System32"]),
  })
  let path = WinPath({
    disk: 'C',
    path: @immut/list.T::of(["Windows", "System32"]),
  })
  inspect!(path.starts_with(base), content="true")
  inspect!(path.starts_with(base2), content="true")

  // Test Windows paths with different disks but same path
  let other_disk = WinPath({ disk: 'D', path: @immut/list.T::of(["Windows"]) })
  inspect!(path.starts_with(other_disk), content="false")
}

test "starts_with/unix" {
  // Test Unix paths with matching prefix
  let base = UnixPath({ path: @immut/list.T::of(["usr", "bin"]) })
  let base2 = UnixPath({ path: @immut/list.T::of(["bin"]) })
  let path = UnixPath({ path: @immut/list.T::of(["usr", "bin", "python"]) })
  inspect!(path.starts_with(base), content="true")
  inspect!(path.starts_with(base2), content="false")

  // Test Unix paths with different prefixes
  let different = UnixPath({ path: @immut/list.T::of(["usr", "local"]) })
  inspect!(path.starts_with(different), content="false")
}

test "starts_with/cross_type" {
  // Test mixing Windows and Unix paths
  let win = WinPath({ disk: 'C', path: @immut/list.T::of(["Users"]) })
  let unix = UnixPath({ path: @immut/list.T::of(["Users"]) })
  inspect!(win.starts_with(unix), content="false")
  inspect!(unix.starts_with(win), content="false")

  // Test empty paths
  let empty_win = WinPath({ disk: 'C', path: @immut/list.T::Nil })
  let empty_unix = UnixPath({ path: @immut/list.T::Nil })
  inspect!(empty_win.starts_with(empty_unix), content="false")
}

///|
/// Determines whether child is a suffix of self.
/// Only considers whole path components to match.
pub fn ends_with(self : Path, child : Path) -> Bool {
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
    path: @immut/list.T::of(["Users", "Documents", "file.txt"]),
  })
  let suffix = WinPath({
    disk: 'C',
    path: @immut/list.T::of(["Documents", "file.txt"]),
  })
  inspect!(path.ends_with(suffix), content="true")

  // Test different disk letters
  let diff_disk = WinPath({
    disk: 'D',
    path: @immut/list.T::of(["Documents", "file.txt"]),
  })
  inspect!(path.ends_with(diff_disk), content="false")

  // Test empty paths
  let empty = WinPath({ disk: 'C', path: @immut/list.T::Nil })
  inspect!(path.ends_with(empty), content="true")
}

test "ends_with/unix" {
  // Test path suffix matching with root
  let path = UnixPath({ path: @immut/list.T::of(["", "usr", "local", "bin"]) })
  let suffix = UnixPath({ path: @immut/list.T::of(["local", "bin"]) })
  inspect!(path.ends_with(suffix), content="true")

  // Test longer suffix than path
  let longer = UnixPath({
    path: @immut/list.T::of(["opt", "usr", "local", "bin"]),
  })
  inspect!(path.ends_with(longer), content="false")

  // Test empty suffix
  let empty = UnixPath({ path: @immut/list.T::Nil })
  inspect!(path.ends_with(empty), content="true")
}

test "ends_with/cross_type" {
  let win_path = WinPath({
    disk: 'C',
    path: @immut/list.T::of(["Users", "Documents"]),
  })
  let unix_path = UnixPath({ path: @immut/list.T::of(["Users", "Documents"]) })

  // Test mixing path types
  inspect!(win_path.ends_with(unix_path), content="false")
  inspect!(unix_path.ends_with(win_path), content="false")
}

///|
pub fn with_file_name(self : Path, name : String) -> Path {
  match self {
    WinPath(x) =>
      match x.path {
        Nil => WinPath({ path: @immut/list.T::of([name]), disk: x.disk })
        Cons(_, rest) => WinPath({ path: Cons(name, rest), disk: x.disk })
      }
    UnixPath(x) =>
      match x.path {
        Nil => UnixPath({ path: @immut/list.T::of([name]) })
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
    win_path(winpath.with_file_name("new.txt")),
    content="C:\\Users\\Documents\\new.txt",
  )

  // Empty path case
  let empty_win = WinPath({ disk: 'D', path: @immut/list.T::Nil })
  inspect!(
    win_path(empty_win.with_file_name("file.txt")),
    content="D:\\file.txt",
  )
}

test "with_file_name/unix" {
  // Normal case with multiple components
  let unixpath = UnixPath({ path: to_path(["home", "user", "doc.txt"]) })
  inspect!(
    unix_path(unixpath.with_file_name("new.txt")),
    content="/home/user/new.txt",
  )

  // Empty path case
  let empty_unix = UnixPath({ path: @immut/list.T::Nil })
  inspect!(
    unix_path(empty_unix.with_file_name("file.txt")),
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
    win_path(path.with_file_name("file with spaces.txt")),
    content="C:\\Users\\Documents\\file with spaces.txt",
  )
  inspect!(
    win_path(path.with_file_name("file#1.txt")),
    content="C:\\Users\\Documents\\file#1.txt",
  )
}

///|
pub fn with_extension(self : Path, extension : String) -> Path {
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
    win_path(winpath.with_extension("doc")),
    content="C:\\Users\\file.doc",
  )
  inspect!(unix_path(unixpath.with_extension("doc")), content="/home/file.doc")
}

test "with_extension/empty" {
  // Test with empty extension and no extension
  let winpath = WinPath({ disk: 'C', path: to_path(["Users", "file.txt"]) })
  let win_no_ext = WinPath({ disk: 'C', path: to_path(["Users", "file"]) })
  inspect!(win_path(winpath.with_extension("")), content="C:\\Users\\file")
  inspect!(win_path(win_no_ext.with_extension("")), content="C:\\Users\\file")
}

test "with_extension/multiple_dots" {
  // Test with multiple dots in filename
  let winpath = WinPath({ disk: 'C', path: to_path(["Users", "file.tar.gz"]) })
  let unixpath = UnixPath({ path: to_path(["home", "file.tar.gz"]) })
  inspect!(
    win_path(winpath.with_extension("xz")),
    content="C:\\Users\\file.tar.xz",
  )
  inspect!(
    unix_path(unixpath.with_extension("xz")),
    content="/home/file.tar.xz",
  )
}

///|
pub fn with_added_extension(self : Path, extension : String) -> Path {
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
    win_path(winpath.with_added_extension("txt")),
    content="C:\\Users\\file.txt",
  )
  inspect!(
    unix_path(unixpath.with_added_extension("txt")),
    content="/home/file.txt",
  )
}

test "with_added_extension/empty" {
  // Test with empty extension
  let winpath = WinPath({ disk: 'C', path: to_path(["Users", "file"]) })
  let unixpath = UnixPath({ path: to_path(["home", "file"]) })

  // Empty extension should return original path
  inspect!(
    win_path(winpath.with_added_extension("")),
    content="C:\\Users\\file",
  )
  inspect!(unix_path(unixpath.with_added_extension("")), content="/home/file")
}

test "with_added_extension/existing_extension" {
  // Test adding extension to files that already have extensions
  let winpath = WinPath({ disk: 'C', path: to_path(["Users", "file.txt"]) })
  let unixpath = UnixPath({ path: to_path(["home", "file.txt"]) })
  inspect!(
    win_path(winpath.with_added_extension("gz")),
    content="C:\\Users\\file.txt.gz",
  )
  inspect!(
    unix_path(unixpath.with_added_extension("gz")),
    content="/home/file.txt.gz",
  )
}
