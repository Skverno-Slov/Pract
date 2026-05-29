using Microsoft.EntityFrameworkCore;
using Signal.Server.Data;
using Signal.Server.Data.Dtos;
using Signal.Server.Data.Models.Models;

namespace Signal.Server.Services
{
    public class EquipmentService(ApplicationDbContext context)
    {
        private readonly ApplicationDbContext context = context;

        public async Task<PagedLogsResponse> GetEquipmentLogsAsync(string serialNumber,
                                                                   string periodType,
                                                                   string? readingIdentifier, 
                                                                   int page = 1,
                                                                   int pageSize = 20)
        {
            var now = DateTime.UtcNow;
            DateTime? startDate = null;
            DateTime? endDate = null;

            ApplyPeriod(periodType, now, ref startDate, ref endDate);

            var availableIdentifiers = await context.ReadingLogs
                .Where(rl => rl.Equipment.SerialNumber == serialNumber)
                .Select(rl => rl.ReadingType.Identifier)
                .Distinct()
                .ToListAsync();

            var query = context.ReadingLogs
                .Where(rl => rl.Equipment.SerialNumber == serialNumber 
                && rl.Status.Name.ToLower() != "ok");

            if (startDate.HasValue) query = query.Where(rl => rl.WriteDateTime >= startDate.Value);
            if (endDate.HasValue) query = query.Where(rl => rl.WriteDateTime < endDate.Value);

            if (!string.IsNullOrEmpty(readingIdentifier))
            {
                query = query.Where(rl => rl.ReadingType.Identifier == readingIdentifier);
            }

            int totalCount = await query.CountAsync();

            var logs = await query
                .OrderByDescending(rl => rl.WriteDateTime)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(rl => new ReadingLogResponse(
                    rl.ReadingType.Name,
                    rl.Value,
                    rl.ReadingType.Unit,
                    rl.Status.Name,
                    rl.WriteDateTime
                ))
                .ToListAsync();

            return new PagedLogsResponse(logs, availableIdentifiers, totalCount);
        }

        public async Task<List<EquipmentResponse>> GetAllEquipmentAsync()
        {
            return await context.Equipment
                .OrderBy(e => e.Model) 
                .ThenBy(e => e.Name)
                .Select(e => new EquipmentResponse(
                    e.EquipmentId,
                    e.SerialNumber,
                    e.Name,
                    e.Model,
                    e.Status.Name, 
                    e.LastCheckDate
                ))
                .ToListAsync();
        }

        public async Task<List<GraphPointResponse>> GetFullGraphDataAsync(string serialNumber, string periodType)
        {
            var now = DateTime.UtcNow;
            DateTime? startDate = null;
            DateTime? endDate = null;

            ApplyPeriod(periodType, now, ref startDate, ref endDate);

            var query = context.ReadingLogs
                .Where(rl => rl.Equipment.SerialNumber == serialNumber);

            if (startDate.HasValue) query = query.Where(rl => rl.WriteDateTime >= startDate.Value);
            if (endDate.HasValue) query = query.Where(rl => rl.WriteDateTime < endDate.Value);

            return await query
                .OrderBy(rl => rl.WriteDateTime) 
                .Select(rl => new GraphPointResponse(
                    rl.ReadingType.Identifier,
                    rl.Value, 
                    rl.WriteDateTime
                ))
                .ToListAsync();
        }

        public async Task<bool> CheckEquipmentExistsAsync(string serialNumber)
        {
            return await context.Equipment
                .AnyAsync(e => e.SerialNumber == serialNumber);
        }

        public async Task<IEnumerable<LatestReadingResponse>> GetLatestReadingsAsync(string serialNumber)
        {
            return await context.ViewLatestEquipmentReadings
                .Where(r => r.SerialNumber == serialNumber)
                .Select(r => new LatestReadingResponse(
                    r.SerialNumber,
                    r.MetricKey ?? "",
                    r.Label ?? "",
                    r.Value ?? "",
                    r.Unit,
                    r.Status ?? "OK",
                    r.Datetime,
                    r.MinValue,
                    r.MaxValue
                ))
                .ToListAsync();
        }

        private static void ApplyPeriod(string periodType, DateTime now, ref DateTime? startDate, ref DateTime? endDate)
        {
            switch (periodType.ToUpper())
            {
                case "HOUR_1":
                    startDate = now.AddHours(-1);
                    break;

                case "TODAY":
                    startDate = now.Date;
                    break;

                case "YESTERDAY":
                    startDate = now.Date.AddDays(-1);
                    endDate = now.Date;
                    break;

                case "CURRENT_WEEK":
                    int diff = (7 + (now.Date.DayOfWeek - DayOfWeek.Monday)) % 7;
                    startDate = now.Date.AddDays(-1 * diff);
                    break;

                case "LAST_WEEK":
                    int lastWeekDiff = (7 + (now.Date.DayOfWeek - DayOfWeek.Monday)) % 7;
                    startDate = now.Date.AddDays(-1 * lastWeekDiff).AddDays(-7);
                    endDate = now.Date.AddDays(-1 * lastWeekDiff);
                    break;

                case "CURRENT_MONTH":
                    startDate = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                    break;

                case "LAST_MONTH":
                    var lastMonth = now.AddMonths(-1);
                    startDate = new DateTime(lastMonth.Year, lastMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                    endDate = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                    break;

                case "ALL_TIME":
                default:
                    break;
            }
        }
    }
}
