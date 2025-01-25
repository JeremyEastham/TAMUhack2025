from uuid import uuid4

import bcrypt
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.responses import RedirectResponse

from tamuhack.api.dependencies import CurrentSession
from tamuhack.db.models import User, Session

router = APIRouter()


@router.get( "/" )
async def root():
    return RedirectResponse( url = "/docs" )


@router.post( "/register", status_code = status.HTTP_201_CREATED )
async def register( username: str, password: str ):
    existing_user = await User.filter( username = username ).first()
    if existing_user is not None:
        raise HTTPException( status_code = status.HTTP_409_CONFLICT, detail = "username_taken" )
    hashed_password = bcrypt.hashpw( password.encode( "utf-8" ), bcrypt.gensalt() ).hex()
    user = await User.create( username = username, hashed_password = hashed_password )
    print( f"Created user: {user}" )


@router.post( "/login", status_code = status.HTTP_200_OK )
async def login( form_data: OAuth2PasswordRequestForm = Depends() ):
    user = await User.get( username = form_data.username )
    if user is None:
        raise HTTPException( status_code = status.HTTP_401_UNAUTHORIZED, detail = "invalid_username" )
    if not bcrypt.checkpw( form_data.password.encode( "utf-8" ), bytes.fromhex( user.hashed_password ) ):
        raise HTTPException( status_code = status.HTTP_401_UNAUTHORIZED, detail = "invalid_password" )
    token = uuid4().hex
    await Session.create( token = token, user = user )
    print( f"Logged in {user.username} with token {token}" )
    return { "access_token": token, "token_type": "bearer" }


@router.post( "/logout", status_code = status.HTTP_200_OK )
async def logout( session: Session = Depends( CurrentSession ) ):
    print( f"Logged out {session.user.username} with token {session.token}" )
    await session.delete()
