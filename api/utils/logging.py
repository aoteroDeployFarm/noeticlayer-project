from __future__ import annotations

import logging
import os
import sys


def configure_logging() -> None:
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()

    logging.basicConfig(
        level=log_level,
        format=(
            "%(asctime)s "
            "%(levelname)s "
            "%(name)s "
            "request_id=%(request_id)s "
            "message=%(message)s"
        ),
        stream=sys.stdout,
    )


class RequestIdFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        if not hasattr(record, "request_id"):
            record.request_id = "-"
        return True


def get_logger(name: str) -> logging.Logger:
    configure_logging()

    logger = logging.getLogger(name)
    logger.addFilter(RequestIdFilter())

    return logger