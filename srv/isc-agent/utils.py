import base64
import hashlib
import hmac
import os

import settings


class BaseModel(settings.DATABASE_BASE):
    __abstract__ = True

    def __repr__(self):
        return f'{self.__class__.__name__}({self})'

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)

    def to_dict(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}


def get_auth():
    nonce = base64.b64encode(os.urandom(8)).decode()
    myhash = hmac.new(
        (nonce + settings.DSHIELD_USER_ID).encode('utf-8'),
        msg=settings.DSHIELD_API_KEY.encode('utf-8'),
        digestmod=hashlib.sha256
    ).digest()
    hash64 = base64.b64encode(myhash).decode()
    return 'ISC-HMAC-SHA256 Credentials=%s Userid=%s Nonce=%s' % (
        hash64,
        settings.DSHIELD_USER_ID,
        nonce.rstrip()
    )
