typealias PurePath=@immut/list.T[String]

///|
struct Path {
  path : PurePath
  desk : Char
}

///|
pub fn path(str : String) -> Path {
  { path: Cons(str, Nil), desk: '?' }
}

///|
fn op_add(self : Path, b : Path) -> Path {
  { path: self.path.concat(b.path), desk: self.desk }
}

///|
pub fn join(self : Path, b : Path) -> Path {
  { path: self.path.concat(b.path), desk: self.desk }
}

///|
pub fn parent(self : Path) -> Path {
  match self.path {
    Nil => self
    Cons(_, xs) => { path: xs, desk: self.desk }
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
  loop path.path, "" {
    Nil, str => break str
    Cons(str, rest), other => continue rest, "/\{str}\{other}"
  }
}

///|
pub fn win_path(path : Path) -> String {
  loop path.path, "" {
    Nil, str => break "\{path.desk}:\{str}"
    Cons(str, rest), other => continue rest, "\\\{str}\{other}"
  }
}

///|
fn main {
  let arr = ["abc", "cde", "333"]
  let arr2 = ["abcc", "cded", "3333"]
  let l : Path = { path: to_path(arr), desk: 'D' }
  let ll : Path = { path: to_path(arr2), desk: 'D' }
  println(win_path(l))
  println(win_path(ll))
  println(unix_path(l + ll))
}