import cgi
import os

from google.appengine.api import users
from google.appengine.ext import webapp, db
from google.appengine.ext.webapp import template
from google.appengine.ext.webapp.util import run_wsgi_app

from utils import *
from models import *

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

class WaitingCodes(Handler):
    def get(self):
        codes = DeviceRegistration.all()
        with_template(self, 'codes.html', { 'codes': codes })

class RequestCode(Handler):
    def get(self):
        code = DeviceRegistration()
        code.code = make_code()
        code.put()

        with_template(self, 'code.xml', { 'code': code })

class CompleteForm(Handler):
    def get(self):
        with_template(self, 'reg_form.html')

class CompleteRegistration(Handler):
    @httpexcept
    def post(self):
        code_str = self.request.get('code')
        regtype_str = self.request.get('type')

        # validate the code, this throws on failure
        code = DeviceRegistration.for_code(code_str)

        # determine the registration type and update the state
        if(regtype_str.lower() == 'device'):
            code.update_state(DEVICE_REGISTERED_EVENT)
        elif(regtype_str.lower() == 'server'):
            code.update_state(SERVER_REGISTERED_EVENT)
            server_str = self.request.get('server')
            code.server = server_str

        code.put()

class RegistrationState(Handler):
    @httpexcept
    def get(self):
        code_str = self.request.get('code')
        code = DeviceRegistration.for_code(code_str)
        with_template(self, "state.xml", { 'code': code })
        
class MainPage(Handler):
    def get(self):
        greetings = db.GqlQuery("SELECT * FROM Greeting ORDER BY date DESC LIMIT 10")
        if users.get_current_user():
            log_url = users.create_logout_url(self.request.uri)
            log_text = 'Logout'
        else:
            log_url = users.create_login_url(self.request.uri)
            log_text = 'Login'

        data = {
            'greetings': greetings,
            'log_url': log_url,
            'log_text': log_text }

        with_template(self, "index.html", data)

class Guestbook(Handler):
    def post(self):

        greeting = Greeting()
        if users.get_current_user():
            greeting.author = users.get_current_user()
        greeting.content = self.request.get('content')
        greeting.put()
        self.redirect('/')

application = webapp.WSGIApplication(
    [('/', MainPage),
     ('/sign', Guestbook),
     ('/codes', WaitingCodes),
     ('/code', RequestCode),
     ('/regdebug', CompleteForm),
     ('/register', CompleteRegistration),
     ('/state', RegistrationState)],
    debug=True)

def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()

