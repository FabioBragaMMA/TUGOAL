using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TuGoalAPI.Data;
using TuGoalAPI.Models;

namespace TuGoalAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EquipasController : ControllerBase
    {
        private readonly TuGoalDbContext _context;

        public EquipasController(TuGoalDbContext context)
        {
            _context = context;
        }

        // Qualquer pessoa pode ver as equipas
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Equipa>>> GetEquipas()
        {
            return await _context.Equipas.Where(e => e.Ativo).ToListAsync();
        }

        // Só Perfil "Administrador" pode adicionar
        [Authorize(Roles = "Administrador")]
        [HttpPost]
        public async Task<ActionResult<Equipa>> CriarEquipa(Equipa novaEquipa)
        {
            novaEquipa.Ativo = true;
            _context.Equipas.Add(novaEquipa);
            await _context.SaveChangesAsync();

            return Ok(novaEquipa);
        }


        // Editar equipa
        [Authorize(Roles = "Administrador")]
        [HttpPut("{id}")]
        public async Task<IActionResult> EditarEquipa(int id, [FromBody] Equipa equipaAtualizada)
        {
            var equipa = await _context.Equipas.FindAsync(id);
            if (equipa == null) return NotFound("Equipa não encontrada!");

            equipa.Nome = equipaAtualizada.Nome;
            equipa.Ano_Fundacao = equipaAtualizada.Ano_Fundacao;
            equipa.Emblema = equipaAtualizada.Emblema;

            await _context.SaveChangesAsync();

            return Ok(new { mensagem = "Equipa atualizada com sucesso!", equipa });
        }

        // Soft Delete = passa a inativa
        [Authorize(Roles = "Administrador")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> ApagarEquipa(int id)
        {
            var equipa = await _context.Equipas.FindAsync(id);
            if (equipa == null) return NotFound();

            equipa.Ativo = false;
            await _context.SaveChangesAsync();

            return Ok(new { mensagem = "Equipa inativada com sucesso!" });
        }
    }
}