from plugins.tcp.http.main import HealthCheck


def test_temporary():
    HealthCheck()
    return True
