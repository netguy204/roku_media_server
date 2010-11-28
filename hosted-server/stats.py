import cgi, logging, datetime

from google.appengine.api.labs import taskqueue
from google.appengine.ext import db, webapp
from google.appengine.ext.webapp import template
from google.appengine.ext.webapp.util import run_wsgi_app

from django.utils import simplejson

from models import *

# information I'm after:
# How long between:
#  get code -> device reg (fail rate?)
#  device reg -> download (fail rate?)
#  download -> server reg (fail rate?)
#  download count?

# After server reg, how often does device reg and server
# reg happen again? stats requests?

# state machine for building the statistics for a users
# walk through the registration process
class UState:
    START = 0
    CODE_REQUESTED = 1
    DEVICE_REGISTERED = 2
    SERVER_DOWNLOADED = 3
    SERVER_REGISTERED = 4
    ERROR = -1

def incr_status_count(data, name, evt):
    gkey = 'status_count'
    last = 'last_status'
    first = 'first_status'

    key = name + '_' + gkey

    if not first in data:
        data[first] = evt.date.isoformat()

    if not gkey in data:
        data[gkey] = 0

    if not key in data:
        data[key] = 0

    data[key] += 1
    data[gkey] += 1

    data[last] = evt.date.isoformat()

def incr_reg_count(data, evt):
    timekey = evt.regtype + '_reg_time'
    countkey = evt.regtype + '_reg_count'

    data[timekey] = evt.date.isoformat()
    
    if not countkey in data:
        data[countkey] = 0

    data[countkey] += 1

def incr_rereg(data, kind, evt):
    "this is a likely reregistration -- got a server reg without a download"
    rrkey = kind + '_rereg_count'
    if not rrkey in data:
        data[rrkey] = 0
    data[rrkey] += 1

def incr_down_cnt(data, evt):
    key = 'download_count'
    last = 'download_last'
    if not key in data:
        data[key] = 0
    data[key] += 1
    data[last] = evt.date.isoformat()

def incr_code_fail(data, name, evt):
    key = name + '_codefail_count'
    if not key in data:
        data[key] = 0
    data[key] += 1

def incr_download_giveup(data, evt):
    key = 'download_giveup'
    if not key in data:
        data[key] = 0
    data[key] += 1

stat_machine = {
    UState.START: {
        REQUEST_STATUS_USEREVENT: (UState.START,
                                   lambda d,e: incr_status_count(d, 'start', e)),
        REGISTER_USEREVENT: (UState.DEVICE_REGISTERED, incr_reg_count),
        REQUEST_CODE_USEREVENT: (UState.START,),
        DOWNLOAD_USEREVENT: (UState.START, incr_down_cnt),
        CODEFAILED_USEREVENT: (UState.START,
                               lambda d,e: incr_code_fail(d, 'start', e)),
        },

    UState.DEVICE_REGISTERED: {
        REQUEST_STATUS_USEREVENT: (UState.DEVICE_REGISTERED,
                                   lambda d,e: incr_status_count(d, 'device', e)),
        DOWNLOAD_USEREVENT: (UState.SERVER_DOWNLOADED, incr_down_cnt),
        REGISTER_USEREVENT: (UState.SERVER_REGISTERED,),
        CODEFAILED_USEREVENT: (UState.DEVICE_REGISTERED,
                               lambda d,e: incr_code_fail(d, 'device', e)),
        },
    
    UState.SERVER_DOWNLOADED: {
        REQUEST_STATUS_USEREVENT: (UState.SERVER_DOWNLOADED,
                                   lambda d,e: incr_status_count(d, 'down', e)),
        DOWNLOAD_USEREVENT: (UState.SERVER_DOWNLOADED, incr_down_cnt),
        REGISTER_USEREVENT: (UState.SERVER_REGISTERED,),
        CODEFAILED_USEREVENT: (UState.SERVER_DOWNLOADED,
                               lambda d,e: incr_code_fail(d, 'download', e)),
        },

    UState.SERVER_REGISTERED: {
        REQUEST_STATUS_USEREVENT: (UState.SERVER_REGISTERED,
                                   lambda d,e: incr_status_count(d, 'server', e)),
        REGISTER_USEREVENT: (UState.SERVER_REGISTERED, incr_reg_count,
                             lambda d,e: incr_rereg(d, 'resync', e)),
        DOWNLOAD_USEREVENT: (UState.SERVER_REGISTERED, incr_down_cnt),
        CODEFAILED_USEREVENT: (UState.SERVER_REGISTERED,
                               lambda d,e: incr_code_fail(d, 'server', e)),
        },
    }

def get_code(data, evt):
    # first try the event itself
    if evt.ev_type in (REQUEST_CODE_USEREVENT, REQUEST_STATUS_USEREVENT,
                       REGISTER_USEREVENT):
        return evt.code
    
    # next try our records for that ip
    if evt.requester in data:
        for record in reversed(data[evt.requester]):
            if 'code' in record:
                return record['code']

    # can't figure it out
    return False

def get_record(data, evt):
    if not evt.requester in data:
        return False

    records = data[evt.requester]
    last = records[-1]
    
    if last['code'] == get_code(data, evt):
        return last
    else:
        return False

def process_event_stream(events, data = {}):

    for event in events:
        rec = get_record(data, event)

        # make a new record if there wasn't one
        if not rec:
            rec = { 'state': UState.START,
                    'code': get_code(data, event) }
            if not event.requester in data:
                data[event.requester] = []
            data[event.requester].append(rec)

        #logging.warning(rec['state'])
        #logging.warning(event.ev_type)
        #logging.warning(stat_machine[rec['state']])

        # now iterate the state machine
        try:
            steps = stat_machine[rec['state']][event.ev_type]
            next_state = steps[0]
            for fn in steps[1:]:
                fn(rec, event)
        except Exception, e:
            next_state = UState.ERROR
            ex = 'exceptions'
            if not ex in rec:
                rec[ex] = []

            rec[ex].append(str(e))

        rec['state'] = next_state
        data['last_event_time'] = event.date.isoformat()

    return data

def str2time(str):
    dt, _, us = str.partition(".")
    dt = datetime.datetime.strptime(dt, "%Y-%m-%dT%H:%M:%S")
    us = int(us.rstrip("Z"), 10)
    return dt + datetime.timedelta(microseconds=us)
    
class Worker(webapp.RequestHandler):
    def get(self):
        taskqueue.add(url='/stats/stats-worker')
        
    def post(self):
        last = None
        last_json = {}
        finished = 0
        device = 0
        created = 0

        reg_event_count = 0

        regs = DeviceRegistration.all()
        events = UserEvent.all()

        # pull the most recent stat object
        stats = RegistrationStats.all().order('-date').fetch(1)

        if len(stats) == 1:
            last = stats[0]
            last_json = simplejson.loads(last.event_stats)

            if 'last_event_time' in last_json:
                finished = last.finished_count
                device = last.device_count
                created = last.created_count

                last_ev_time = str2time(last_json['last_event_time'])
                logging.debug("last_event_time = %s" % last_ev_time)
                regs.filter('date >', last_ev_time)
                events.filter('date >', last_ev_time)
        else:
            last = RegistrationStats()

        regs.order('date')
        events.order('date')

        for reg in regs:
            created += 1
            reg_event_count += 1

            if reg.state == BOTH_REGISTERED_STATE:
                finished += 1
            elif reg.state == DEVICE_REGISTERED_STATE:
                device += 1

        logging.debug("total regs processed: %d" % reg_event_count)

        last.finished_count = finished
        last.device_count = device
        last.created_count = created

        # now process events
        ev_data = process_event_stream(events, last_json)
        
        last.event_stats = simplejson.dumps(ev_data)
        last.date = datetime.datetime.now()

        last.put()

class Display(webapp.RequestHandler):
    def get(self):
        stats = RegistrationStats.all().order('-date').fetch(1)
        with_template(self, 'stats.html', { 'stats': stats })

    def post(self):
        taskqueue.add(url='/stats/stats-worker')
        self.redirect('/stats/')

class UserStats(Handler):
    def get(self):
        stats = RegistrationStats.all().order('-date').fetch(1)
        
        self.response.headers['Content-Type'] = 'text/plain'

        if(len(stats) == 1):
            json = simplejson.loads(stats[0].event_stats)
            self.response.out.write(simplejson.dumps(json, sort_keys=True, indent=2))
        else:
            self.response.out.write("{}")
        
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
     ('/stats/json', UserStats),
     ('/stats/', Display)],
    debug=True)

def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()
