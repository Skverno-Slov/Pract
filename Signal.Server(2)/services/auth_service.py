import datetime
from contextlib import asynccontextmanager
import bcrypt
import jwt
from pydantic import BaseModel
from psycopg_pool import AsyncConnectionPool
from psycopg.rows import dict_row

SECRET_KEY = "12345678123456781234567812345678"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_DAYS = 30

DATABASE_URL = "postgresql://user1:123@localhost:5432/signal_track_db"

pool = AsyncConnectionPool(conninfo=DATABASE_URL, open=False)

class RegisterRequest(BaseModel):
    login: str  
    password: str
    first_name: str
    last_name: str
    middle_name: str | None = None  
    position: str | None = None

class UserModel(BaseModel):
    user_id: int
    hashed_password: str

class AuthService:
    
    @classmethod
    @asynccontextmanager
    async def get_connection(cls):
        if pool.closed:
            await pool.open()
        async with pool.connection() as conn:
            conn.row_factory = dict_row 
            yield conn

    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        if not hashed_password.startswith(("$2b$", "$2a$")):
            return plain_password == hashed_password
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

    @staticmethod
    def generate_jwt_tokens(user_id: int) -> dict:
        now = datetime.datetime.now(datetime.timezone.utc)
        return {
            "access_token": jwt.encode({
                "sub": str(user_id), 
                "exp": now + datetime.timedelta(minutes=15)
            }, SECRET_KEY, algorithm=ALGORITHM),
            "refresh_token": jwt.encode({
                "sub": str(user_id), 
                "exp": now + datetime.timedelta(days=30)
            }, SECRET_KEY, algorithm=ALGORITHM)
        }

    @classmethod
    async def authenticate_user(cls, login: str, password_raw: str) -> dict | None:
        async with cls.get_connection() as conn:
            async with conn.cursor() as cur:
                await cur.execute(
                    'SELECT user_id, hashed_password FROM "user" WHERE login = %s',
                    (login,)
                )
                row = await cur.fetchone()
                
                if not row:
                    return None
                
                user = UserModel(**row)
                
                if not cls.verify_password(password_raw, user.hashed_password):
                    return None
                
                tokens = cls.generate_jwt_tokens(user.user_id)
                
                expire_date = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=30)
                await cur.execute(
                    """
                    INSERT INTO session (user_id, refresh_token, device, session_end_date_time)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (user.user_id, tokens["refresh_token"], "Android Client", expire_date)
                )

                await conn.commit()
                
                return tokens
            
    @classmethod
    async def refresh_user_tokens(cls, refresh_token: str) -> dict | None:
        try:
            payload = jwt.decode(refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
            user_id = int(payload.get("sub"))
        except (jwt.PyJWTError, ValueError, TypeError):
            return None 

        async with cls.get_connection() as conn:
            async with conn.cursor() as cur:
                now = datetime.datetime.now(datetime.timezone.utc)
                await cur.execute(
                    """
                    SELECT id FROM session 
                    WHERE user_id = %s AND refresh_token = %s AND session_end_date_time > %s
                    """,
                    (user_id, refresh_token, now)
                )
                session = await cur.fetchone()
                if not session:
                    return None  
                
                new_tokens = cls.generate_jwt_tokens(user_id)
                new_expire_date = now + datetime.timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)

                await cur.execute(
                    """
                    UPDATE session 
                    SET refresh_token = %s, session_end_date_time = %s
                    WHERE id = %s
                    """,
                    (new_tokens["refresh_token"], new_expire_date, session["id"])
                )
                await conn.commit()
                
                return new_tokens
    
    @staticmethod
    def hash_password(password: str) -> str:
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
        return hashed.decode('utf-8')

    @classmethod
    async def register_user(cls, data: RegisterRequest) -> bool:
        hashed_pwd = cls.hash_password(data.password)
        
        async with cls.get_connection() as conn:
            async with conn.cursor() as cur:
                try:
                    await cur.execute(
                        "CALL create_new_user(%s, %s, %s, %s, %s, %s)",
                        (
                            data.login, 
                            hashed_pwd, 
                            data.first_name, 
                            data.last_name, 
                            data.middle_name, 
                            data.position
                        )
                    )
                    await conn.commit()
                    return True
                except Exception as e:
                    print(f"Ошибка регистрации пользователя: {e}")
                    await conn.rollback()
                    return False
