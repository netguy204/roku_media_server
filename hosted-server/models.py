from utils import *

from google.appengine.ext import webapp, db

REQUEST_CODE_USEREVENT = 0
REQUEST_STATUS_USEREVENT = 1
REGISTER_USEREVENT = 2
CODEFAILED_USEREVENT = 3
DOWNLOAD_USEREVENT = 4

class UserEvent(db.Expando):
    date = db.DateTimeProperty(auto_now_add=True)

    ev_type = db.IntegerProperty(required=True, indexed=True)
    requester = db.StringProperty(required=True, indexed=True)

def spawn_event(hdlr, ev_type, **kwargs):
    return UserEvent(ev_type=ev_type, requester=hdlr.request.remote_addr, **kwargs)

# define state machine constants
NOTHING_REGISTERED_STATE = 0
DEVICE_REGISTERED_STATE = 1
SERVER_REGISTERED_STATE = 2
BOTH_REGISTERED_STATE = 3
DEVICE_REGISTERED_EVENT = 0
SERVER_REGISTERED_EVENT = 1


class DeviceRegistration(db.Model):
    code = db.StringProperty()
    state = db.IntegerProperty(default = NOTHING_REGISTERED_STATE)
    date = db.DateTimeProperty(auto_now_add=True)
    server = db.StringProperty(default = "UNKNOWN")

    @classmethod
    def for_code(klass, code_str):
        codes = DeviceRegistration.gql("WHERE code = :1", code_str)
        if(codes.count() != 1):
            raise HTTPException(404)
        return codes[0]

    def update_state(self, new_event):
        table = {
            NOTHING_REGISTERED_STATE: {
                DEVICE_REGISTERED_EVENT: DEVICE_REGISTERED_STATE,
                SERVER_REGISTERED_EVENT: SERVER_REGISTERED_STATE },
            DEVICE_REGISTERED_STATE: {
                DEVICE_REGISTERED_EVENT: DEVICE_REGISTERED_STATE,
                SERVER_REGISTERED_EVENT: BOTH_REGISTERED_STATE },
            SERVER_REGISTERED_STATE: {
                DEVICE_REGISTERED_EVENT: BOTH_REGISTERED_STATE,
                SERVER_REGISTERED_EVENT: SERVER_REGISTERED_STATE },
            BOTH_REGISTERED_STATE: {
                DEVICE_REGISTERED_EVENT: BOTH_REGISTERED_STATE,
                SERVER_REGISTERED_EVENT: BOTH_REGISTERED_STATE } }
        
        self.state = table[self.state][new_event]
        return self.state
    
    def state_str(self):
        if(self.state == NOTHING_REGISTERED_STATE):
            return "NOTHING_REGISTERED"
        elif(self.state == DEVICE_REGISTERED_STATE):
            return "DEVICE_REGISTERED"
        elif(self.state == SERVER_REGISTERED_STATE):
            return "SERVER_REGISTERED"
        elif(self.state == BOTH_REGISTERED_STATE):
            return "BOTH_REGISTERED"

    
class RegistrationStats(db.Model):
    date = db.DateTimeProperty(auto_now_add=True, indexed=True)

    finished_count = db.IntegerProperty(indexed=False)
    device_count = db.IntegerProperty(indexed=False)
    created_count = db.IntegerProperty(indexed=False)

    event_stats = db.TextProperty()

