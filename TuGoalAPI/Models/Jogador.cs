using System.ComponentModel.DataAnnotations;

namespace TuGoalAPI.Models
{
    public class Jogador
    {
        [Key]
        public int ID_Jogador { get; set; }
        public string Nome { get; set; }
        public string Posicao { get; set; }
        public int Numero_Camisola { get; set; }
        public int ID_Equipa { get; set; }
        public bool Ativo { get; set; }
    }
}