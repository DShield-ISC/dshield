from twisted.web import server, resource
from twisted.internet import reactor, endpoints
from twisted.web.http import Request

from plugins.tcp.http.models import prepare_database


class HealthCheck(resource.Resource):
    isLeaf = True
    numberRequests = 0

    def render_GET(self, request: Request):
        self.numberRequests += 1
        request.setHeader(b"content-type", b"text/plain")
        content = f"I am request #{self.numberRequests}\n"
        return content.encode("ascii")


def handler():
    prepare_database()
    endpoints.serverFromString(reactor, "tcp:8000").listen(server.Site(HealthCheck()))
    return reactor.run()
