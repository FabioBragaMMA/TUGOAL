using System.ComponentModel.DataAnnotations;

namespace TuGoalAPI.Models
{
    public class CampeonatoEquipa
    {
        [Key]
        public int ID_Camp_Eq { get; set; }
        public int ID_Campeonato { get; set; }
        public int ID_Equipa { get; set; }
    }
}