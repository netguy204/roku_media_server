from google.appengine.ext.webapp import template
from google.appengine.ext import webapp, db
from google.appengine.api import users

import random
import os

basepath = os.path.dirname(__file__)
def with_template(hdlr, name, data = {}):
    "render a template based in the working directory"
    tmpl = os.path.join(basepath, name)

    ext = os.path.splitext(name)[1]
    ext_type = 'text/plain'
    if(ext == ".xml"):
        ext_type = 'text/xml'
    elif(ext == ".html"):
        ext_type = 'text/html'
    hdlr.response.headers['Content-Type'] = ext_type
    hdlr.response.out.write(template.render(tmpl, data))

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
        except HTTPException, e:
            args[0].error(e.code)
    new_func.__name__ = func.__name__
    new_func.__doc__ = func.__doc__
    new_func.__dict__.update(func.__dict__)
    return new_func

class Handler(webapp.RequestHandler):
    pass

    
