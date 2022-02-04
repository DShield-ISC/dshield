import logging
from http import HTTPStatus

from twisted.web import server, resource
from twisted.internet import reactor, endpoints
from twisted.web.http import Request

from plugins.tcp.http.models import prepare_database

DEFAULT_PORTS = [80, 8000, 8080]
PRODSTRING = 'Apache/3.2.3'
logger = logging.getLogger(__name__)




class Web(resource.Resource):
    isLeaf = True
    numberRequests = 0

    def render_GET(self, request: Request):
        self.numberRequests += 1
        request.setHeader(b"content-type", b"text/plain")
        content = f"I am request #{self.numberRequests}\n"
        return content.encode("ascii")

    def render_HEAD(self, request: Request):
        request.setResponseCode(HTTPStatus.OK)
        request.setHeader('Server', PRODSTRING)
        request.setHeader('Access-Control-Allow-Origin', '*')
        request.setHeader('content-type', 'text/plain')
        logger.info(request.getClientAddress())
        request.finish()

    def render_CONNECT(self, request: Request):
        request.setHeader('Server', PRODSTRING)
        request.setHeader('Access-Control-Allow-Origin', '*')
        request.setHeader('content-type', 'text/plain')
        logger.info('Request type is %s', request.method)
        logger.info('Client IP: %s ', request.getClientAddress())




def handler(**kwargs):
    prepare_database()
    ports = kwargs.get('ports', DEFAULT_PORTS)
    for port in ports:
        endpoints.serverFromString(reactor, f'tcp:{port}').listen(server.Site(Web()))
