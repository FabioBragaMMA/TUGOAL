using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TuGoalAPI.Data;
using TuGoalAPI.Models;

namespace TuGoalAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class JogosController : ControllerBase
    {
        private readonly TuGoalDbContext _context;
        private readonly Random _random = new Random();

        public JogosController(TuGoalDbContext context)
        {
            _context = context;
        }

        // Ver a lista de jogos
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Jogo>>> GetJogos()
        {
            return await _context.Jogos
                .OrderBy(j => j.Jornada)
                .ThenBy(j => j.ID_Jogo)
                .ToListAsync();
        }

        // Agendar um jogo novo
        [Authorize(Roles = "Administrador")]
        [HttpPost]
        public async Task<ActionResult<Jogo>> AgendarJogo([FromBody] Jogo novoJogo)
        {
            novoJogo.Estado_Jogo = string.IsNullOrWhiteSpace(novoJogo.Estado_Jogo)
                ? "Por jogar"
                : novoJogo.Estado_Jogo;

            _context.Jogos.Add(novoJogo);
            await _context.SaveChangesAsync();
            return Ok(novoJogo);
        }

        // Atualizar o resultado manualmente
        [Authorize(Roles = "Administrador")]
        [HttpPut("{id}/terminar")]
        public async Task<IActionResult> TerminarJogo(int id, [FromBody] ResultadoJogoRequest resultado)
        {
            var jogo = await _context.Jogos.FindAsync(id);
            if (jogo == null) return NotFound(new { mensagem = "Jogo não encontrado!" });

            jogo.Golos_Casa = resultado.Golos_Casa;
            jogo.Golos_Fora = resultado.Golos_Fora;
            jogo.Estado_Jogo = "Terminado";

            await MarcarCampeonatoEmCurso(jogo.ID_Campeonato);
            await _context.SaveChangesAsync();

            return Ok(new { mensagem = "Resultado atualizado com sucesso!", jogo });
        }

        // Gera calendário com TODAS as equipas ativas atuais.
        // Só funciona antes de existirem jogos terminados para não estragar uma época já começada.
        [Authorize(Roles = "Administrador")]
        [HttpPost("gerar-calendario")]
        public async Task<IActionResult> GerarCalendario()
        {
            var campeonato = await _context.Campeonatos
                .OrderBy(c => c.ID_Campeonato)
                .FirstOrDefaultAsync();

            if (campeonato == null)
            {
                campeonato = new Campeonato
                {
                    Nome = "Liga TuGoal",
                    Data_Inicio = DateTime.Today,
                    Data_Fim = DateTime.Today.AddMonths(9),
                    Estado = "Por iniciar"
                };
                _context.Campeonatos.Add(campeonato);
                await _context.SaveChangesAsync();
            }

            var epocaJaComecou = await _context.Jogos.AnyAsync(j => j.Estado_Jogo == "Terminado");
            if (epocaJaComecou)
            {
                return BadRequest(new
                {
                    mensagem = "A época já começou. Reinicia a época antes de gerar um novo calendário."
                });
            }

            var equipas = await _context.Equipas
                .Where(e => e.Ativo)
                .OrderBy(e => e.ID_Equipa)
                .ToListAsync();

            if (equipas.Count < 2)
            {
                return BadRequest(new { mensagem = "É preciso pelo menos 2 equipas ativas para gerar jornadas." });
            }

            // Limpa calendário antigo por jogar, porque pode estar desatualizado com equipas antigas.
            var eventosAntigos = await _context.Eventos_Jogo.ToListAsync();
            _context.Eventos_Jogo.RemoveRange(eventosAntigos);

            var jogosAntigos = await _context.Jogos.ToListAsync();
            _context.Jogos.RemoveRange(jogosAntigos);
            await _context.SaveChangesAsync();

            var jogosNovos = CriarCalendarioRoundRobin(
                campeonato.ID_Campeonato,
                equipas.Select(e => e.ID_Equipa).ToList()
            );

            _context.Jogos.AddRange(jogosNovos);
            campeonato.Estado = "Por iniciar";

            await _context.SaveChangesAsync();

            return Ok(new
            {
                mensagem = "Calendário gerado com sucesso com as equipas atuais!",
                totalEquipas = equipas.Count,
                totalJogos = jogosNovos.Count,
                totalJornadas = jogosNovos.Any() ? jogosNovos.Max(j => j.Jornada) : 0
            });
        }

        // Simula uma jornada inteira no backend.
        // Isto garante que a base de dados fica atualizada e a classificação muda logo.
        [Authorize(Roles = "Administrador")]
        [HttpPost("simular-jornada/{jornada}")]
        public async Task<IActionResult> SimularJornada(int jornada)
        {
            if (jornada < 1)
            {
                return BadRequest(new { mensagem = "A jornada tem de ser maior que 0." });
            }

            var jogosDaJornada = await _context.Jogos
                .Where(j => j.Jornada == jornada)
                .OrderBy(j => j.ID_Jogo)
                .ToListAsync();

            if (!jogosDaJornada.Any())
            {
                return BadRequest(new { mensagem = "Não existem jogos para esta jornada." });
            }

            var existemJogosAnterioresPorJogar = await _context.Jogos.AnyAsync(j =>
                j.Jornada < jornada && j.Estado_Jogo != "Terminado");

            if (existemJogosAnterioresPorJogar)
            {
                return BadRequest(new
                {
                    mensagem = "Tens de terminar as jornadas anteriores antes de simular esta jornada."
                });
            }

            var jogosPorSimular = jogosDaJornada
                .Where(j => j.Estado_Jogo != "Terminado")
                .ToList();

            if (!jogosPorSimular.Any())
            {
                return BadRequest(new { mensagem = "Esta jornada já está toda terminada." });
            }

            foreach (var jogo in jogosPorSimular)
            {
                jogo.Golos_Casa = _random.Next(0, 5);
                jogo.Golos_Fora = _random.Next(0, 5);
                jogo.Estado_Jogo = "Terminado";
                await MarcarCampeonatoEmCurso(jogo.ID_Campeonato);
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                mensagem = $"Jornada {jornada} simulada com sucesso!",
                totalJogosSimulados = jogosPorSimular.Count,
                jogos = jogosPorSimular
            });
        }

        // Reiniciar época: apaga jogos/eventos e deixa o campeonato por iniciar.
        // Depois, ao abrir Registar Jogos no Flutter, o calendário é gerado com as equipas atuais.
        [Authorize(Roles = "Administrador")]
        [HttpPost("resetar-epoca")]
        public async Task<IActionResult> ResetarEpoca()
        {
            var eventos = await _context.Eventos_Jogo.ToListAsync();
            _context.Eventos_Jogo.RemoveRange(eventos);

            var jogos = await _context.Jogos.ToListAsync();
            _context.Jogos.RemoveRange(jogos);

            var campeonatos = await _context.Campeonatos.ToListAsync();
            foreach (var campeonato in campeonatos)
            {
                campeonato.Estado = "Por iniciar";
            }

            await _context.SaveChangesAsync();
            return Ok(new { mensagem = "Época reiniciada. O campeonato está por iniciar." });
        }

        private List<Jogo> CriarCalendarioRoundRobin(int idCampeonato, List<int> idsEquipas)
        {
            var lista = new List<int>(idsEquipas);

            // Se for número ímpar, -1 representa folga.
            if (lista.Count % 2 != 0)
            {
                lista.Add(-1);
            }

            int totalEquipas = lista.Count;
            int totalJornadas = totalEquipas - 1;
            int jogosPorJornada = totalEquipas / 2;
            var dataBase = DateTime.Today.AddDays(7).Date.AddHours(20);
            var jogos = new List<Jogo>();

            for (int jornada = 1; jornada <= totalJornadas; jornada++)
            {
                for (int i = 0; i < jogosPorJornada; i++)
                {
                    int casa = lista[i];
                    int fora = lista[totalEquipas - 1 - i];

                    if (casa == -1 || fora == -1)
                    {
                        continue;
                    }

                    if (jornada % 2 == 0)
                    {
                        (casa, fora) = (fora, casa);
                    }

                    jogos.Add(new Jogo
                    {
                        ID_Campeonato = idCampeonato,
                        Jornada = jornada,
                        Data_Hora = dataBase.AddDays((jornada - 1) * 7).AddMinutes(i * 105),
                        ID_Equipa_Casa = casa,
                        ID_Equipa_Fora = fora,
                        Golos_Casa = null,
                        Golos_Fora = null,
                        Estado_Jogo = "Por jogar"
                    });
                }

                // Método circular: fixa a primeira equipa e roda as restantes.
                int ultimo = lista[totalEquipas - 1];
                lista.RemoveAt(totalEquipas - 1);
                lista.Insert(1, ultimo);
            }

            return jogos;
        }

        private async Task MarcarCampeonatoEmCurso(int idCampeonato)
        {
            var campeonato = await _context.Campeonatos.FindAsync(idCampeonato);
            if (campeonato != null)
            {
                campeonato.Estado = "Em Curso";
            }
        }
    }
}
