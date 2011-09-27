import cgi, datetime

from google.appengine.api import users
from google.appengine.ext import webapp, db
from google.appengine.ext.webapp.util import run_wsgi_app

from utils import *
from models import *

class RequestCode(Handler):
    def get(self):
        code = DeviceRegistration()

        # produce a code and verify it's unique
        code_str = make_code()
        unique_code = False
        while not unique_code:
            try:
                DeviceRegistration.for_code(code_str)
                code_str = make_code() # need to try again
            except:
                unique_code = True

        code.code = code_str
        code.put()

        spawn_event(self, REQUEST_CODE_USEREVENT,
                    code=code.code).put()

        with_template(self, 'code.xml', { 'code': code })

class CompleteRegistration(Handler):
    @httpexcept
    def post(self):
        code_str = self.request.get('code')
        regtype_str = self.request.get('type').lower()

        # validate the code, this throws on failure
        try:
            code = DeviceRegistration.for_code(code_str)
        except:
            spawn_event(self, CODEFAILED_USEREVENT,
                        code=code_str,
                        regtype=regtype_str).put()

            with_template(self, 'index.html', {
                    'error': "The code %s is not recognized" % code_str})
            return

        # determine the registration type and update the state
        if(regtype_str == 'device'):
            code.update_state(DEVICE_REGISTERED_EVENT)
        elif(regtype_str == 'server'):
            code.update_state(SERVER_REGISTERED_EVENT)
            server_str = self.request.get('server')
            code.server = server_str

        code.date = datetime.datetime.now()
        code.put()

        spawn_event(self, REGISTER_USEREVENT,
                    code=code_str,
                    regtype=regtype_str).put()

        self.redirect('/walkthrough')

class RegistrationState(Handler):
    @httpexcept
    def get(self):
        code_str = self.request.get('code')
        code = DeviceRegistration.for_code(code_str)

        spawn_event(self, REQUEST_STATUS_USEREVENT,
                    code=code_str).put()

        with_template(self, "state.xml", { 'code': code })

class MainPage(Handler):
    def get(self):
        with_template(self, "index.html")

class Walkthrough(Handler):
    def get(self):
        with_template(self, 'walkthrough.html')

class Download(Handler):
    def get(self):
        spawn_event(self, DOWNLOAD_USEREVENT).put()
        self.redirect("http://github.com/netguy204/roku_media_server/zipball/channel")

application = webapp.WSGIApplication(
    [('/', MainPage),
     ('/code', RequestCode),
     ('/register', CompleteRegistration),
     ('/state', RegistrationState),
     ('/walkthrough', Walkthrough),
     ('/download', Download)],
    debug=True)

def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()

