from twisted.web import server, resource
from twisted.internet import reactor, endpoints
from twisted.web.http import Request


class HealthCheck(resource.Resource):
    isLeaf = True
    numberRequests = 0

    def render_GET(self, request: Request):
        self.numberRequests += 1
        request.setHeader(b"content-type", b"text/plain")
        content = f"I am request #{self.numberRequests}\n"
        return content.encode("ascii")

    def do_HEAD(self, request):
        request.setResonseCode(200)
        request.setHeader(b"")


def handler():
    endpoints.serverFromString(reactor, "tcp:8000").listen(server.Site(HealthCheck()))
    return reactor.run()
