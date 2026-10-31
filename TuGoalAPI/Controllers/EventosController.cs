using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TuGoalAPI.Data;
using TuGoalAPI.Models;

namespace TuGoalAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EventosController : ControllerBase
    {
        private readonly TuGoalDbContext _context;

        public EventosController(TuGoalDbContext context)
        {
            _context = context;
        }

        // pede os golos e cartões de um jogo específico (para o ecrã de detalhes)
        [HttpGet("jogo/{jogoId}")]
        public async Task<ActionResult<IEnumerable<EventoJogo>>> GetEventosDoJogo(int jogoId)
        {
            return await _context.Eventos_Jogo
                .Where(e => e.ID_Jogo == jogoId)
                .ToListAsync();
        }

        // registar golo ou cartão num jogo
        [Authorize(Roles = "Administrador")]
        [HttpPost]
        public async Task<ActionResult<EventoJogo>> RegistarEvento([FromBody] EventoJogo novoEvento)
        {
            _context.Eventos_Jogo.Add(novoEvento);
            await _context.SaveChangesAsync();
            return Ok(novoEvento);
        }
    }
}