using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Signal.Server.Data.Dtos;
using Signal.Server.Services;
using System.Security.Claims;

namespace SignalTrack.Api.Controllers;

[ApiController]
[Route("api/equipment")] 
public class EquipmentController(EquipmentService equipmentService) : ControllerBase
{
    private readonly EquipmentService equipmentService = equipmentService;

    [Authorize]
    [HttpGet("{serialNumber}/logs")]
    public async Task<IActionResult> GetEquipmentLogs(
    [FromRoute] string serialNumber,
    [FromQuery] string period = "ALL_TIME",
    [FromQuery] string? identifier = null,
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 30)
    {
        var result = await equipmentService.GetEquipmentLogsAsync(serialNumber, period, identifier, page, pageSize);
        return Ok(result);
    }

    [Authorize]
    [HttpGet("{serialNumber}/graph")]
    public async Task<IActionResult> GetGraphData([FromRoute] string serialNumber, [FromQuery] string period = "ALL_TIME")
    {
        var points = await equipmentService.GetFullGraphDataAsync(serialNumber, period);
        return Ok(points);
    }

    [Authorize]
    [HttpGet]
    public async Task<IActionResult> GetDevices()
    {
        var devices = await equipmentService.GetAllEquipmentAsync();
        return Ok(devices);
    }

    [HttpPost("logs")]
    public async Task<IActionResult> Create([FromBody] CreateReadingLogDto dto)
    {
        try
        {
            var result = await equipmentService.AddReadingLogAsync(dto);
            return StatusCode(201, result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Внутренняя ошибка сервера", details = ex.Message });
        }
    }

    [Authorize]
    [HttpGet("{serialNumber}/latest")]
    public async Task<ActionResult<IEnumerable<LatestReadingResponse>>> GetLatestReadings(string serialNumber)
    {
        var exists = await equipmentService.CheckEquipmentExistsAsync(serialNumber);
        if (!exists)
        {
            return NotFound($"Прибор с серийным номером '{serialNumber}' не найден.");
        }

        var readings = await equipmentService.GetLatestReadingsAsync(serialNumber);
        return Ok(readings);
    }

}
