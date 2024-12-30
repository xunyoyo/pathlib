///|
enum PurePath {
  Cons(String, PurePath)
  Nil
}

///|
struct Path {
  path : PurePath
  desk : Char
}

///|
pub fn to_path(str : Array[String]) -> PurePath {
  let mut path = Nil
  for item in str {
    path = Cons(item, path)
  }
  path
}

///|
pub fn unix_path(path : Path) -> String {
  loop path.path, "" {
    Nil, str => break str
    Cons(str, rest), other => {
      continue rest, "/\{str}\{other}"
    }
  }
}

///|
pub fn win_path(path : Path) -> String {
  loop path.path, "" {
    Nil, str => break "\{path.desk}:\\\{str}"
    Cons(str, rest), other => {
      continue rest, "\\\{str}\{other}"
    }
  }
}

///|
fn main {
  let arr = ["abc", "cde", "333"]
  let l : Path = {path : to_path(arr), desk : 'D'}
  println(win_path(l))
}
