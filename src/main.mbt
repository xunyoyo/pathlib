enum PurePath {
  Cons(String, PurePath)
  Nil
}

struct Path {
  path : PurePath
  desk : Char
}


pub fn to_path(str : Array[String]) -> PurePath {
  let mut path = Nil
  for item in str {
    path = Cons(item, path)
  }
  path
}

pub fn unix_path(path : Path) -> String {
  let mut pth = ""
  loop path.path {
    Nil => break pth
    Cons(str, rest) => {
      pth = "\{pth}/\{str}"
      continue rest
    }
  }
}

pub fn win_path(path : Path) -> String {
  let mut pth = ""
  loop path.path {
    Nil => break "\{path.desk}:\\\\\{pth}"
    Cons(str, rest) => {
      pth = "\{pth}\\\{str}"
      continue rest
    }
  }
}



fn main {
  let arr = ["abc", "cde", "333"]
  let l = to_path(arr)
  // println(unix_path(l))
}