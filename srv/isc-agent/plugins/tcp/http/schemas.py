from enum import Enum
from functools import reduce
from http import HTTPStatus
from typing import List, Optional, Dict

from pydantic import BaseModel, conlist, root_validator


class Condition(str, Enum):
    absent = 'absent'
    contains = 'contains'
    equal = 'equal'
    regex = 'regex'


class Response(BaseModel):
    id: int
    headers: Dict[str, str]
    body: Optional[str] = ''
    status_code: Optional[HTTPStatus] = HTTPStatus.OK


class Rule(BaseModel):
    attribute: str
    condition: Optional[Condition] = Condition.contains
    value: str
    score: Optional[int] = 1
    required: Optional[bool] = False


class Signature(BaseModel):
    id: int
    responses: conlist(int, min_items=1)
    rules: List[Rule]

    @root_validator
    def validate_max_score(cls, values):
        values['max_score'] = reduce(lambda x, y: x + y, [rule.score for rule in values['rules']], 0)
        return values
