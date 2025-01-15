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
pub fn extension(self : Path) -> String {
  match self {
    WinPath(x) =>
      match x.path {
        Nil => ""
        Cons(file, _) => {
          let idx = file.index_of(".")
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
          let idx = file.index_of(".")
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
  let arr = ["abc", "cde", "333.txt"]
  let arr2 = ["abc", "cde", "333"]
  let l : Path = WinPath({ path: to_path(arr), disk: 'D' })
  let ll : Path = WinPath({ path: to_path(arr2), disk: 'D' })
  println(win_path(l))
  println(l.file_stem())
  println(l.extension())
  println(win_path(ll))
  println(ll.file_stem())
  println(ll.extension())
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
