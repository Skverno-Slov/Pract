using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Signal.Server.Data.Dtos;
using Signal.Server.Services;
using System.Security.Claims;

namespace SignalTrack.Api.Controllers;

[ApiController]
[Route("api/auth")] 
public class AuthController(AuthService authService) : ControllerBase
{
    private readonly AuthService authService = authService;

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest payload, [FromHeader(Name = "X-Device-Name")] string? deviceName)
    {
        var device = string.IsNullOrEmpty(deviceName) ? "Unknown Android Device" : Uri.UnescapeDataString(deviceName);

        var tokens = await authService.AuthenticateUserAsync(payload.Login, payload.Password, device);
        if (tokens == null) return Unauthorized(new { detail = "Неверный логин или пароль" });
        return Ok(tokens);
    }

    [HttpPost("logout")]
    public async Task<IActionResult> Logout([FromBody] RefreshRequest payload)
    {
        await authService.InvalidateSessionAsync(payload.RefreshToken);
        return Ok(new { message = "Сессия успешно удалена" });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest payload)
    {
        var newTokens = await authService.RefreshUserTokensAsync(payload.RefreshToken);
        if (newTokens is null)
        {
            return Unauthorized(new { detail = "Невалидный refresh-токен. Требуется повторный вход." });
        }
        return Ok(newTokens);
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest payload)
    {
        var success = await authService.RegisterUserAsync(payload);
        if (!success)
        {
            return BadRequest(new { detail = "Такой логин уже занят." });
        }
        return StatusCode(201, new { message = "Пользователь успешно зарегистрирован" });
    }
}
