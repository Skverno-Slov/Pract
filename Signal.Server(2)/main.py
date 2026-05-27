from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from services.auth_service import AuthService, RegisterRequest, pool
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="SignalTrack API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class TokenResponse(BaseModel):
    access_token: str = Field(..., serialization_alias="accessToken")
    refresh_token: str = Field(..., serialization_alias="refreshToken")

class LoginRequest(BaseModel):
    login: str
    password: str

class RefreshRequest(BaseModel):
    refreshToken: str

@app.on_event("shutdown")
async def shutdown_event():
    await pool.close()

@app.post("/api/auth/login", response_model=TokenResponse) 
async def login(payload: LoginRequest):
    tokens = await AuthService.authenticate_user(payload.login, payload.password)
    if not tokens:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Неверный логин или пароль")
    return tokens 

@app.post("/api/auth/refresh", response_model=TokenResponse) 
async def refresh(payload: RefreshRequest):
    new_tokens = await AuthService.refresh_user_tokens(payload.refreshToken)
    if not new_tokens:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Невалидный refresh-токен. Требуется повторный вход."
        )
    return new_tokens

@app.post("/api/auth/register", status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest):
    success = await AuthService.register_user(payload)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Такой логин уже занят."
        )
    return {"message": "Пользователь успешно зарегистрирован"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)