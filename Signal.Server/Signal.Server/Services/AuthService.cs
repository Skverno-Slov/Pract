using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Signal.Server.Data;
using Signal.Server.Data.Dtos;
using Signal.Server.Data.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using static System.Collections.Specialized.BitVector32;

namespace Signal.Server.Services
{
    public class AuthService(ApplicationDbContext context)
    {
        private readonly ApplicationDbContext context = context;

        private byte[] key = AuthOptions.keyBytes;

        public bool VerifyPassword(string inputPassword, string hashedPassword)
            => BCrypt.Net.BCrypt.Verify(inputPassword, hashedPassword);

        public string HashPassword(string password)
            => BCrypt.Net.BCrypt.HashPassword(password, workFactor: 11);

        public TokenResponse GenerateJwtTokens(int userId,
                                               string? first = null,
                                               string? last = null,
                                               string? middle = null)
        {
            var tokenHandler = new JwtSecurityTokenHandler();

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity([new Claim(JwtRegisteredClaimNames.Sub, userId.ToString())]),
                Expires = DateTime.UtcNow.AddMinutes(15),
                Issuer = AuthOptions.validIssuer,
                Audience = AuthOptions.validAudience,
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), AuthOptions.algorithm)
            };
            var accessToken = tokenHandler.CreateToken(tokenDescriptor);

            var refreshDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[] { new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()) }),
                Expires = DateTime.UtcNow.AddDays(3),
                Issuer = AuthOptions.validIssuer,
                Audience = AuthOptions.validAudience,
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), AuthOptions.algorithm)
            };
            var refreshToken = tokenHandler.CreateToken(refreshDescriptor);

            return new TokenResponse(
                tokenHandler.WriteToken(accessToken),
                tokenHandler.WriteToken(refreshToken),
                first, last, middle
            );
        }

        public async Task<TokenResponse?> AuthenticateUserAsync(string login, string passwordRaw, string deviceName)
        {
            var user = await context.users.FirstOrDefaultAsync(u => u.login == login);
            if (user is null || !VerifyPassword(passwordRaw, user.hashed_password))
            {
                return null;
            }

            var tokens = GenerateJwtTokens(user.user_id, user.first_name, user.second_name, user.last_name);

            var session = new session
            {
                user_id = user.user_id,
                refresh_token = tokens.RefreshToken,
                device = deviceName, 
                session_end_date_time = DateTime.UtcNow.AddDays(3) 
            };

            context.sessions.Add(session);
            await context.SaveChangesAsync();

            return tokens;
        }

        public async Task<TokenResponse?> RefreshUserTokensAsync(string refreshToken)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                var validationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidIssuer = AuthOptions.validIssuer,
                    ValidAudience = AuthOptions.validAudience,
                    ClockSkew = TimeSpan.Zero
                };

                var principal = tokenHandler.ValidateToken(refreshToken, validationParameters, out _);
                var userIdStr = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? principal.FindFirst("sub")?.Value
                ?? principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

                if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out int userId)) return null;

                var now = DateTime.UtcNow;
                var session = await context.sessions
                    .FirstOrDefaultAsync(s => s.user_id == userId 
                    && s.refresh_token == refreshToken 
                    && s.session_end_date_time > now);

                if (session is null) return null;

                var user = await context.users.FindAsync(userId);

                var newTokens = GenerateJwtTokens(userId, user?.first_name, user?.second_name, user?.last_name);

                session.refresh_token = newTokens.RefreshToken;
                session.session_end_date_time = DateTime.UtcNow.AddDays(3);

                await context.SaveChangesAsync();
                return newTokens;
            }
            catch { return null; }
        }

        public async Task<bool> InvalidateSessionAsync(string refreshToken)
        {
            var session = await context.sessions.FirstOrDefaultAsync(s => s.refresh_token == refreshToken);
            if (session is not null)
            {
                context.sessions.Remove(session);
                await context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public async Task<bool> RegisterUserAsync(RegisterRequest data)
        {
            var hashedPwd = HashPassword(data.HashedPassword);

            try
            {
                await context.Database.ExecuteSqlRawAsync(
                    "CALL create_new_user({0}, {1}, {2}, {3}, {4}, {5})",
                    data.Login, hashedPwd, data.FirstName, data.LastName, data.MiddleName, data.Role
                );
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка регистрации пользователя: {ex.Message}");
                return false;
            }
        }
    }
}
