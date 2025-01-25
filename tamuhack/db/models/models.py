from tortoise import fields
from tortoise.models import Model


class Session( Model ):
    token = fields.CharField( required = True, unique = True, max_length = 32 )
    user = fields.ForeignKeyField(
        "models.User", related_name = "sessions", null = True
    )


class User( Model ):
    username = fields.CharField(
        required = True, max_length = 255, unique = True
    )
    hashed_password = fields.CharField(
        required = True, max_length = 255
    )
    sessions: fields.ReverseRelation[ "Session" ]
