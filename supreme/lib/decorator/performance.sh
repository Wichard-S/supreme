python -m timeit -s "
from decorator import decorator

@decorator
def do_nothing(func, *args, **kw):
    return func(*args, **kw) 

@do_nothing
def f():
    pass
" "f()"

python -m timeit -s "
def f():
    pass
" "f()"
