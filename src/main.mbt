///| 
typealias PurePath = @immut/list.T[String]

///|
struct WPath {
  path : PurePath
  desk : String
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
pub fn path(str : String) -> PurePath {
  Cons(str, Nil)
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
        WinPath(xs) => WinPath({ path: x.path.concat(xs.path), desk: x.desk })
        UnixPath(xs) => WinPath({ path: x.path.concat(xs.path), desk: x.desk })
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
        desk: x.desk,
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
  loop str.length() - 1, PurePath::Nil {
    -1, acc => break acc
    i, acc => continue i - 1, Cons(str[i], acc)
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
        Nil, str => break "\{x.desk}:\{str}"
        Cons(str, rest), other => continue rest, "\\\{str}\{other}"
      }
    _ => ""
  }
}

///|
fn main {
  let arr = ["abc", "cde", "333"]
  let arr2 = ["abcc", "cded", "3333"]
  let l : Path = WinPath({ path: to_path(arr), desk: "D" })
  let ll : Path = WinPath({ path: to_path(arr2), desk: "D" })
  println(win_path(l))
  println(win_path(ll.parent()))
  println(win_path((l + ll).parent()))
}
