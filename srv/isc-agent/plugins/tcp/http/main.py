from http import HTTPStatus
from twisted.web import server, resource
from twisted.internet import reactor, endpoints
from twisted.web.http import Request

PRODSTRING = 'Apache/3.2.3'


class HealthCheck(resource.Resource):
    isLeaf = True
    numberRequests = 0

    def render_GET(self, request: Request):
        self.numberRequests += 1
        request.setHeader(b"content-type", b"text/plain")
        content = f"I am request #{self.numberRequests}\n"
        return content.encode("ascii")

    def render_HEAD(self, request):
        request_type = request.getHeader('HEAD')
        request.setResponseCode(HTTPStatus.OK)
        request.setHeader(b"Server", f"{PRODSTRING}")
        request.setHeader(b"Access-Control-Allow-Origin", "*")
        request.setHeader(b"content-type", b"text/plain")
        content = f"I am HEAD request #{self.numberRequests}\n"
        return content.encode("ascii")


def handler():
    endpoints.serverFromString(reactor, "tcp:8000").listen(server.Site(HealthCheck()))
    return reactor.run()
