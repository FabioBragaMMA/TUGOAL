using System.ComponentModel.DataAnnotations;

namespace TuGoalAPI.Models
{
    public class Jogo
    {
        [Key]
        public int ID_Jogo { get; set; }
        public int ID_Campeonato { get; set; }
        public int Jornada { get; set; }
        public DateTime Data_Hora { get; set; }
        public int ID_Equipa_Casa { get; set; }
        public int ID_Equipa_Fora { get; set; }
        public int? Golos_Casa { get; set; } // '?' significa que permite ser NULL
        public int? Golos_Fora { get; set; }
        public string Estado_Jogo { get; set; }
    }
}