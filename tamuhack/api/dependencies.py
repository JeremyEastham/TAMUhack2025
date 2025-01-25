from datetime import datetime

from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from starlette.status import HTTP_401_UNAUTHORIZED

from tamuhack.db.models import User, Session

BearerToken = OAuth2PasswordBearer( tokenUrl = "/login" )


async def CurrentSession( token: str = Depends( BearerToken ) ) -> Session:
    if token is None:
        raise HTTPException( status_code = HTTP_401_UNAUTHORIZED, detail = "token_required" )
    session = await Session.filter( token = token ).first()
    if session is None:
        raise HTTPException( status_code = HTTP_401_UNAUTHORIZED, detail = "invalid_token" )
    return session


async def CurrentUser( session: Session = Depends( CurrentSession ) ) -> User:
    return session.user
