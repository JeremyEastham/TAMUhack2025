import os
from contextlib import asynccontextmanager
from traceback import print_exc
from typing import AsyncGenerator

from fastapi import FastAPI
from tortoise.contrib.fastapi import RegisterTortoise

from tamuhack.db import config
from tamuhack.db.models import Session

DELETE_DB_ON_STARTUP = True


async def startup( app: FastAPI ) -> None:
    # The server just started, the database is not connected yet
    print( "[STARTUP]" )


async def on_database_connected( app: FastAPI ) -> None:
    # The server is started and the database is connected
    print( "[DATABASE_CONNECTED]" )
    await Session.all().delete()


async def shutdown( app: FastAPI ) -> None:
    # The server is shutting down, but the database is still connected
    print( "[SHUTDOWN]" )


async def post_shutdown( app: FastAPI ) -> None:
    # The server is shutting down, the database is disconnected
    print( "[POST_SHUTDOWN]" )


@asynccontextmanager
async def lifespan( app: FastAPI ) -> AsyncGenerator[ None, None ]:
    def print_error( hook_name: str ):
        print( f'An error occurred in the "{hook_name}" hook!' )
        print_exc()

    # noinspection PyBroadException
    try:
        await startup( app )
    except:
        print_error( "initialize" )
        yield
        return
    if DELETE_DB_ON_STARTUP and os.path.exists( "database.db" ):
        os.remove( "database.db" )
    async with RegisterTortoise(
            app = app,
            config = config,
            generate_schemas = True,
            add_exception_handlers = True,
            _create_db = True,
    ):
        try:
            await on_database_connected( app )
        except:
            print_error( "on_database_connected" )
        yield
        try:
            await shutdown( app )
        except:
            print_error( "shutdown" )
    try:
        await post_shutdown( app )
    except:
        print_error( "post_shutdown" )
