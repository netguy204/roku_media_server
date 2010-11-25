import cgi

from google.appengine.api.labs import taskqueue
from google.appengine.ext import db
from google.appengine.ext import webapp
from google.appengine.ext.webapp import template
from google.appengine.ext.webapp.util import run_wsgi_app

from models import *

class RegistrationStats(db.Model):
    date = db.DateTimeProperty(auto_now_add=True, indexed=True)

    finished_count = db.IntegerProperty(indexed=False)
    device_count = db.IntegerProperty(indexed=False)
    created_count = db.IntegerProperty(indexed=False)

class Worker(webapp.RequestHandler):
    def post(self):
        regs = DeviceRegistration.all()

        finished = 0
        device = 0
        created = 0

        for reg in regs:
            created += 1

            if reg.state == BOTH_REGISTERED_STATE:
                finished += 1
            elif reg.state == DEVICE_REGISTERED_STATE:
                device += 1

        stats = RegistrationStats()
        stats.finished_count = finished
        stats.device_count = device
        stats.created_count = created
        stats.put()

class Display(webapp.RequestHandler):
    def get(self):
        stats = RegistrationStats.all().order('-date').fetch(1)
        with_template(self, 'stats.html', { 'stats': stats })

    def post(self):
        taskqueue.add(url='/stats/stats-worker')
        self.redirect('/stats/')


class WaitingCodes(Handler):
    def get(self):
        codes = DeviceRegistration.all()
        with_template(self, 'codes.html', { 'codes': codes })

class CompleteForm(Handler):
    def get(self):
        with_template(self, 'reg_form.html')

application = webapp.WSGIApplication(
    [('/stats/codes', WaitingCodes),
     ('/stats/regdebug', CompleteForm),
     ('/stats/stats-worker', Worker),
     ('/stats/', Display)],
    debug=True)

def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()
