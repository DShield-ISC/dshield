from enum import Enum
from functools import reduce
from http import HTTPStatus
from typing import List, Optional, Dict

from pydantic import BaseModel, conlist, root_validator


class Condition(str, Enum):
    absent = 'absent'
    contain = 'contain'
    equal = 'equal'
    regex = 'regex'


class Response(BaseModel):
    id: int
    headers: Dict[str, str]
    body: Optional[str] = ''
    status_code: Optional[HTTPStatus] = HTTPStatus.OK


class Rule(BaseModel):
    attribute: str
    condition: Optional[Condition] = Condition.contain
    value: str
    score: Optional[int] = 1
    required: Optional[bool] = False


class Signature(BaseModel):
    id: int
    responses: conlist(int, min_items=1)
    rules: List[Rule]

    @root_validator(skip_on_failure=True)
    def validate_max_score(cls, values):  # pylint: disable=no-self-argument
        values['max_score'] = reduce(lambda x, y: x + y, [rule.score for rule in values['rules']], 0)
        values['rules'].sort(key=lambda rule: rule.required, reverse=True)
        return values
