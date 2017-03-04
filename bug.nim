type
  Kucing*[T] = object
    trans: ptr T
    
proc initKucing*[T](trans: var T): Kucing[T] =
  mixin transform
  var 
    x = 0.0
    y = 0.0
  result.trans = trans.addr
  result.trans[].transform(x, y)
  
mixin not work in template

forward declaration in template