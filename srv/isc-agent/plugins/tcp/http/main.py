from twisted.web import server, resource
from twisted.internet import reactor, endpoints
from twisted.web.http import Request

from plugins.tcp.http.models import prepare_database

DEFAULT_PORTS = [80, 8000, 8080]


class Web(resource.Resource):
    isLeaf = True
    numberRequests = 0

    def render_GET(self, request: Request):
        self.numberRequests += 1
        request.setHeader(b"content-type", b"text/plain")
        content = f"I am request #{self.numberRequests}\n"
        return content.encode("ascii")


def handler(**kwargs):
    prepare_database()
    ports = kwargs.get('ports', DEFAULT_PORTS)
    for port in ports:
        endpoints.serverFromString(reactor, f'tcp:{port}').listen(server.Site(Web()))
