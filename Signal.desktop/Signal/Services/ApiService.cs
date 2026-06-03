using Signal.Dtos;
using Signal.Models;
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
        const int ClientTimeoutSeconds = 15;
        const string ApiName = "SignalTrack.Api";
        HttpClient client = new();

        private static readonly Lazy<ApiService> instance =
        new Lazy<ApiService>(() => new ApiService());

        public static ApiService Instance => instance.Value;

        private ApiService()
        {
            ConfigureClient();
        }

        public async Task<bool> CheckConnectionAsync(Uri testUri)
        {
            try
            {
                var responce = await client.GetAsync(testUri);
                var content = await responce.Content.ReadFromJsonAsync<PingResponce>();
                return content.Service == ApiName;
            }
            catch
            {
                return false;
            }
        }

        public async Task LogutAsync()
        {
            try
            {
                await client.PostAsJsonAsync("api/auth/logout", SessionContext.RefreshToken);
            }
            catch { }
        }

        public async Task<bool> LoginAsync(string loign, string password)
        {
            try
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
            catch
            {
                return false;
            }
        }

        public async Task<bool> RefreshTokensAsync()
        {
            try
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
            catch
            {  
                return false; 
            }
        }

        private void ConfigureClient()
        {
            var address = SettingsService.Load().Address;
            var port = SettingsService.Load().Port;

            client.BaseAddress = new Uri($"https://{address}:{port}/");
            client.Timeout = TimeSpan.FromSeconds(ClientTimeoutSeconds);
        }
    }
}
