using Signal.Dtos;
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Threading.Tasks;

namespace Signal.Services
{
    public class ApiService
    {
        const int clientTimeoutSeconds = 15;
        HttpClient client = new();
        NetworkSettings settings = new();

        private static readonly Lazy<ApiService> instance =
        new Lazy<ApiService>(() => new ApiService());

        public static ApiService Instance => instance.Value;

        private ApiService()
        {
            ConfigureClient();
        }

        public async Task LogutAsync()
        {
            await client.PostAsJsonAsync("api/auth/logout", SessionContext.RefreshToken);
        }

        public async Task<bool> LoginAsync(string loign, string password)
        {
            var request = new LoginRequest()
            {
                Login = loign,
                Password = password
            };
            var responce = await client.PostAsJsonAsync("api/auth/login", request);
            var content = await responce.Content.ReadFromJsonAsync<TokenResponse>();
            var result = responce.IsSuccessStatusCode;
            if (result)
            {
                SessionContext.AccessToken = content.AccessToken;
                SessionContext.RefreshToken = content.RefreshToken;
            }
            return result;
        }

        public async Task<bool> RefreshTokensAsync()
        {
            var responce = await client.PostAsJsonAsync("api/auth/refresh", SessionContext.RefreshToken);
            var content = await responce.Content.ReadFromJsonAsync<TokenResponse>();
            var result = responce.IsSuccessStatusCode;
            if (result)
            {
                SessionContext.AccessToken = content.AccessToken;
                SessionContext.RefreshToken = content.RefreshToken;
            }
            return result;
        }

        private void ConfigureClient()
        {
            var address = settings.Address;
            var port = settings.Port;

            client.BaseAddress = new Uri($"https://{address}:{port}/");
            client.Timeout = TimeSpan.FromSeconds(clientTimeoutSeconds);
        }
    }
}
