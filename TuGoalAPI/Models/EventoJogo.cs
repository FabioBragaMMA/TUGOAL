using System.ComponentModel.DataAnnotations;

namespace TuGoalAPI.Models
{
    public class EventoJogo
    {
        [Key]
        public int ID_Evento { get; set; }
        public int ID_Jogo { get; set; }
        public int ID_Jogador { get; set; }
        public string Tipo_Evento { get; set; } // Por exemplo: 'Golo', 'Cartão Amarelo'
        public int? Minuto { get; set; }
    }
}