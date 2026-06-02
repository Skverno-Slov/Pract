using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Signal.Server.Data;
using Signal.Server.Data.Dtos;
using Signal.Server.Data.Models;
using Signal.Server.Data.Models.Models;
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
                                               string? first,
                                               string? last,
                                               string? middle,
                                               List<Role> roles)
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

            var roleNames = new List<string>();

            foreach (var role in roles)
            {
                roleNames.Add(role.Name);
            }

            return new TokenResponse(
                tokenHandler.WriteToken(accessToken),
                tokenHandler.WriteToken(refreshToken),
                first, last, middle, roleNames
            );
        }

        public async Task<UserDto?> GetUserAsync(int id)
        {
            return await context.Users
                .Where(u => u.UserId == id)
                .Select(u => new UserDto
                {
                    UserId = u.UserId,
                    Login = u.Login,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    SecondName = u.SecondName
                }).FirstOrDefaultAsync();
        }

        public async Task<List<UserDto>> GetUsersAsync()
        {
            return await context.Users
                .Select(u => new UserDto
                {
                    UserId = u.UserId,
                    Login = u.Login,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    SecondName = u.SecondName
                }).ToListAsync();
        }

        public async Task<TokenResponse?> AuthenticateUserAsync(string login, string passwordRaw, string deviceName)
        {
            var user = await context.Users.FirstOrDefaultAsync(u => u.Login == login);
            if (user is null || !VerifyPassword(passwordRaw, user.HashedPassword))
            {
                return null;
            }

            var tokens = GenerateJwtTokens(user.UserId, user.FirstName, user.SecondName, user.LastName, user.Roles.ToList());

            var session = new Session
            {
                UserId = user.UserId,
                RefreshToken = tokens.RefreshToken,
                Device = deviceName,
                SessionEndDateTime = DateTime.UtcNow.AddDays(3)
            };

            context.Sessions.Add(session);
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
                var session = await context.Sessions
                    .FirstOrDefaultAsync(s => s.UserId == userId
                    && s.RefreshToken == refreshToken
                    && s.SessionEndDateTime > now);

                if (session is null) return null;

                var user = await context.Users.FindAsync(userId);

                var newTokens = GenerateJwtTokens(userId, user?.FirstName, user?.SecondName, user?.LastName, user.Roles.ToList());

                session.RefreshToken = newTokens.RefreshToken;
                session.SessionEndDateTime = DateTime.UtcNow.AddDays(3);

                await context.SaveChangesAsync();
                return newTokens;
            }
            catch { return null; }
        }

        public async Task<bool> InvalidateSessionAsync(string refreshToken)
        {
            var session = await context.Sessions.FirstOrDefaultAsync(s => s.RefreshToken == refreshToken);
            if (session is not null)
            {
                context.Sessions.Remove(session);
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

        public async Task<bool> UpdateUserAsync(int id, UserDto dto)
        {
            var user = await context.Users.FindAsync(id);
            if (user is null) return false;

            if (user.Login != dto.Login)
            {
                bool loginExists = await context.Users.AnyAsync(u => u.Login == dto.Login);
                if (loginExists) throw new InvalidOperationException("Логин уже занят");
            }

            user.Login = dto.Login;
            user.SecondName = dto.SecondName;
            user.FirstName = dto.FirstName;
            user.LastName = dto.LastName;

            await context.SaveChangesAsync();
            return true;
        }


        public async Task<bool> ResetPasswordAsync(int id, string newPassword)
        {
            string hashedNewPassword = HashPassword(newPassword);

            var user = new User { UserId = id };

            context.Entry(user).Property(u => u.HashedPassword).CurrentValue = hashedNewPassword;
            context.Entry(user).Property(u => u.HashedPassword).IsModified = true;

            try
            {
                await context.SaveChangesAsync();
                return true;
            }
            catch (DbUpdateConcurrencyException)
            {
                return false;
            }
        }


        public async Task<bool> DeleteUserAsync(int id)
        {
            var user = await context.Users.FindAsync(id);
            if (user is null) return false;

            context.Users.Remove(user);
            await context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> UpdateUserRolesAsync(int userId, List<int> newRoleIds)
        {
            var user = await context.Users
                .Include(u => u.Roles)
                .FirstOrDefaultAsync(u => u.UserId == userId);

            if (user is null) return false;

            user.Roles.Clear();

            if (newRoleIds is not null && newRoleIds.Count > 0)
            {
                var rolesToAdd = await context.Roles
                    .Where(r => newRoleIds.Contains(r.RoleId))
                    .ToListAsync();

                foreach (var role in rolesToAdd)
                {
                    user.Roles.Add(role);
                }
            }

            context.Entry(user).State = EntityState.Modified;
            await context.SaveChangesAsync();

            return true;
        }
    }
}
