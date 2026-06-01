using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Signal.Server.Data.Dtos;
using Signal.Server.Data.Models.Models;
using Signal.Server.Services;
using System.Security.Claims;

namespace SignalTrack.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(AuthService authService) : ControllerBase
{
    private readonly AuthService authService = authService;

    [HttpGet("{id}")]
    public async Task<ActionResult<UserDto>> GetUserAsync(int id)
    {
        var user = await authService.GetUserAsync(id);
        if (user is null)
            return BadRequest("Пользователь не найден");
        return Ok(user);
    }

    [HttpGet]
    public async Task<ActionResult<List<UserDto>>> GetUsersAsync()
    {
        return await authService.GetUsersAsync();
    }

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
        var result = await authService.RegisterUserAsync(payload);
        if (!result)
        {
            return BadRequest(new { detail = "Ошибка авторизации" });
        }
        return StatusCode(201, new { message = "Пользователь успешно зарегистрирован" });
    }

    [HttpPost("{id}/reset-password")]
    public async Task<IActionResult> ResetPassword(int id, [FromBody] string newPassworrd)
    {
        if (string.IsNullOrWhiteSpace(newPassworrd))
        {
            return BadRequest(new { message = "Новый пароль не может быть пустым" });
        }

        var result = await authService.ResetPasswordAsync(id, newPassworrd);
        if (!result)
        {
            return NotFound(new { message = "Пользователь не найден" });
        }

        return Ok(new { message = "Пароль пользователя успешно изменен" });
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UserDto dto)
    {
        try
        {
            var result = await authService.UpdateUserAsync(id, dto);
            if (!result) return NotFound(new { message = "Пользователь не найден" });

            return Ok(new { message = "Данные успешно обновлены" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await authService.DeleteUserAsync(id);
        if (!result) return NotFound(new { message = "Пользователь не найден" });

        return NoContent();
    }
}
