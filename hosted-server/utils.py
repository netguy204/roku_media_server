import random

from google.appengine.ext import webapp, db

def randchar():
    return chr(ord('a') + random.randint(0, ord('z') - ord('a')))

def make_code(chars = 4):
    return "".join([ randchar() for i in range(chars) ])

if __name__ == "__main__":
    print make_code()

class HTTPException:
    def __init__(self, code):
        self.code = code

def httpexcept(func):
    def new_func(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except HTTPException as e:
            args[0].error(e.code)
    new_func.__name__ = func.__name__
    new_func.__doc__ = func.__doc__
    new_func.__dict__.update(func.__dict__)
    return new_func

class Handler(webapp.RequestHandler):
    pass

    
