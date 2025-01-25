from tortoise import generate_config

config = generate_config(
    "sqlite://database.db",
    app_modules = {
        "models": [ "tamuhack.db.models" ]
    },
)
