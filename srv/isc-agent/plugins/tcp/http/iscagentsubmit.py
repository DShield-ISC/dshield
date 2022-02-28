import logging
import settings
from plugins.tcp.http import models

logger = logging.getLogger(__name__)

logs = models.logs


def test_post():
    logger.warning('ISC-AGENT SUBMIT TO DSHIELD')
    logger.warning('Print Logs')
    logger.warning(logs)
    # logger.warning(logs)
    # d.post(l)
