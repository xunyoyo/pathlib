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
