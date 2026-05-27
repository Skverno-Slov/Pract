using Microsoft.EntityFrameworkCore;
using Signal.Server.Data;
using Signal.Server.Data.Dtos;

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

            var availableIdentifiers = await context.reading_logs
                .Where(rl => rl.equipment.serial_number == serialNumber)
                .Select(rl => rl.reading_type.identifier)
                .Distinct()
                .ToListAsync();

            var query = context.reading_logs
                .AsNoTracking()
                .Where(rl => rl.equipment.serial_number == serialNumber);

            if (startDate.HasValue) query = query.Where(rl => rl.write_date_time >= startDate.Value);
            if (endDate.HasValue) query = query.Where(rl => rl.write_date_time < endDate.Value);

            if (!string.IsNullOrEmpty(readingIdentifier))
            {
                query = query.Where(rl => rl.reading_type.identifier == readingIdentifier);
            }

            int totalCount = await query.CountAsync();

            var logs = await query
                .OrderByDescending(rl => rl.write_date_time)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(rl => new ReadingLogResponse(
                    rl.reading_type.name,
                    rl.value,
                    rl.reading_type.unit,
                    rl.write_date_time
                ))
                .ToListAsync();

            return new PagedLogsResponse(logs, availableIdentifiers, totalCount);
        }

        public async Task<List<EquipmentResponse>> GetAllEquipmentAsync()
        {
            return await context.equipment
                .OrderBy(e => e.model) 
                .ThenBy(e => e.name)
                .Select(e => new EquipmentResponse(
                    e.equipment_id,
                    e.serial_number,
                    e.name,
                    e.model,
                    e.status.name, 
                    e.last_check_date
                ))
                .ToListAsync();
        }

        public async Task<List<GraphPointResponse>> GetFullGraphDataAsync(string serialNumber, string periodType)
        {
            var now = DateTime.UtcNow;
            DateTime? startDate = null;
            DateTime? endDate = null;

            ApplyPeriod(periodType, now, ref startDate, ref endDate);

            var query = context.reading_logs
                .AsNoTracking() 
                .Where(rl => rl.equipment.serial_number == serialNumber);

            if (startDate.HasValue) query = query.Where(rl => rl.write_date_time >= startDate.Value);
            if (endDate.HasValue) query = query.Where(rl => rl.write_date_time < endDate.Value);

            return await query
                .OrderBy(rl => rl.write_date_time) 
                .Select(rl => new GraphPointResponse(
                    rl.reading_type.identifier,
                    rl.value, 
                    rl.write_date_time
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
