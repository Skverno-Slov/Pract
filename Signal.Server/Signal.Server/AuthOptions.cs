using Microsoft.IdentityModel.Tokens;
using System.Text;

namespace Signal.Server
{
    public static class AuthOptions
    {
        public const string secretKey = "12345678123456781234567812345678";
        public static byte[] keyBytes = Encoding.UTF8.GetBytes(secretKey);
        public const string validIssuer = "SignalTrack";
        public const string validAudience = "SignalTrack";
        public const string algorithm = SecurityAlgorithms.HmacSha256;
    }
}
