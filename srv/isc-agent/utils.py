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
