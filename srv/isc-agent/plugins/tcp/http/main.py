from twisted.web import server, resource
from twisted.internet import reactor, endpoints
from twisted.web.http import Request


class HealthCheck(resource.Resource):
    isLeaf = True
    numberRequests = 0

    def render_GET(self, request: Request):
        self.numberRequests += 1
        request.setHeader(b"content-type", b"text/plain")
        content = u"I am request #{}\n".format(self.numberRequests)
        return content.encode("ascii")


def handler():
    endpoints.serverFromString(reactor, "tcp:8000").listen(server.Site(HealthCheck()))
    return reactor.run()
