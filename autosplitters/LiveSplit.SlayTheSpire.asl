/*
	adapted from ClownFiesta AKA FresherDenimAll's splitter: 
		https://github.com/ClownFiesta/AutoSplitters
	overhauled by Ero in May 2022
	debugged by OohBleh in May 2022
*/

state("javaw") {}
state("SlayTheSpire") {}

startup
{
    vars.Log = (Action<object>)(output => print("[Slay the Spire] " + output));
    vars.TryMatch = (Func<string, string, string>)((value, regex) =>
    {
        var match = System.Text.RegularExpressions.Regex.Match(value, regex);
        if (match.Success){
			return match.Groups[1].Value;
		} else{
			return;
		}
		//return new { Success = match.Success, Value = match.Success ? match.Groups[1].Value : null };
    });

    dynamic[,] _settings =
    {
        { null, "startSeed", "Start when generating a new seed",    true },
        { null, "startSlot", "Start when choosing a new save slot", false },
        { null, "resetDeath", "reset on deaths", true },

        { null, "splitLvlChange", "Split on ascension progression",  false },
        { null, "splitVictory", "Split when getting to the victory room", true },
        { null, "splitChest", "Split when reaching a boss chest without killing a boss", true },
        { null, "bosses", "Split when defeating a boss:", true },
            { "bosses", "boss_AUTOMATON", "AUTOMATON", true },
            { "bosses", "boss_CHAMP",     "CHAMP",     true },
            { "bosses", "boss_COLLECTOR", "COLLECTOR", true },
            { "bosses", "boss_CROW",      "CROW",      true },
            { "bosses", "boss_DONUT",     "DONUT",     true },
            { "bosses", "boss_GHOST",     "GHOST",     true },
            { "bosses", "boss_GUARDIAN",  "GUARDIAN",  true },
            { "bosses", "boss_SLIME",     "SLIME",     true },
            { "bosses", "boss_WIZARD",    "WIZARD",    true },

        { null, "ach", "Split when unlocking an achievement:", false },
            { "ach", "ach_RUBY",          "RUBY",          false },
            { "ach", "ach_RUBY_PLUS",     "RUBY_PLUS",     false },
            { "ach", "ach_EMERALD",       "EMERALD",       false },
            { "ach", "ach_EMERALD_PLUS",  "EMERALD_PLUS",  false },
            { "ach", "ach_SAPPHIRE",      "SAPPHIRE",      false },
            { "ach", "ach_SAPPHIRE_PLUS", "SAPPHIRE_PLUS", false },
            { "ach", "ach_AMETHYST",      "AMETHYST",      false },
            { "ach", "ach_AMETHYST_PLUS", "AMETHYST_PLUS", false },
            { "ach", "ach_ASCEND_20",     "ASCEND_20",     false },
            { "ach", "ach_LUCKY_DAY",     "LUCKY_DAY",     false },
            { "ach", "ach_NEON",          "NEON",          false },
            { "ach", "ach_POWERFUL",      "POWERFUL",      false }
    };

    for (int i = 0; i < _settings.GetLength(0); i++)
    {
        var parent = _settings[i, 0];
        var id     = _settings[i, 1];
        var name   = _settings[i, 2];
        var state  = _settings[i, 3];

        settings.Add(id, state, name, parent);
    }
}

init
{
    var relPath = game.ProcessName == "javaw" ? @"\..\.." : "";
    var log = Path.GetDirectoryName(modules.First().FileName) + relPath + @"\sendToDevs\logs\SlayTheSpire.log";
	
	/*
	var log = "";
	if (game.ProcessName == "javaw"){
		log =  System.IO.Directory.GetParent(modules.First().FileName).FullName + "\\..\\..\\sendToDevs\\logs\\SlayTheSpire.log";
	} else{
		log =  System.IO.Directory.GetParent(modules.First().FileName).FullName + "\\sendToDevs\\logs\\SlayTheSpire.log";
	}
	*/
	
    try
    {
        vars.Reader = new StreamReader(new FileStream(log, FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
        vars.Reader.ReadToEnd();
    }
    catch
    {
		vars.Log("Cannot open Slay the Spire log!");
        vars.Log(Path.GetFullPath(log));
        vars.Reader = null;
    }

    current.Line = "";
	current.LinesInLog = 0;
	
	vars.HasKilledBoss = false;
}

update
{
	
	current.Line = vars.Reader.ReadLine();
	
    if (vars.Reader == null){
        return false;
	}
	
    // Check whether file contents were reset.
    current.LinesInLog = vars.Reader.BaseStream.Length;
    if (old.LinesInLog > current.LinesInLog)
    {
		vars.Reader.BaseStream.Position = 0;
        return false;
    }
}

start
{
    // If the line didn't change or we're at the end of the file, we don't care.
    // For convenience.
    var l = current.Line;

    if (old.Line == l || l == null) return;

    if (settings["startSeed"])
    {
        return l.Contains("Generating seeds");
    }

    if (settings["startSlot"])
    {
        return l.Contains("UPDATING DEFAULT SLOT: ");
    }
	
	vars.HasKilledBoss = false;
}

split
{
    var l = current.Line;
	if (old.Line == l || l == null) return;

    
    // Split for level change.
    if (l.Contains("ASCENSION LEVEL IS NOW: "))
    {
        return settings["splitLvlChange"];
    }

    // Split for victory rooms.
    if (l.Contains("VictoryRoom"))
    {
        if (vars.HasKilledBoss)
        {
            vars.HasKilledBoss = false;
            return;
        }

        return settings["splitVictory"];
    }
	
	// Split for boss chest rooms.
    if (l.Contains("TreasureRoomBoss"))
    {
        if (vars.HasKilledBoss)
        {
            vars.HasKilledBoss = false;
            return;
        }

        return settings["splitChest"];
    }
	
	

    // Split for achievements.
    string ach = vars.TryMatch(l, "Achievement Unlocked: (AMETHYST|AMETHYST_PLUS|EMERALD|EMERALD_PLUS|SAPPHIRE|SAPPHIRE_PLUS|RUBY|ASCEND_20|LUCKY_DAY|NEON|POWERFUL)");
    
	if (ach != null)
    {
        return settings["ach_" + ach];
    }

    // Split for boss kills.
    string boss = vars.TryMatch(l, "Hard Unlock: (AUTOMATON|CHAMP|COLLECTOR|CROW|DONUT|GHOST|GUARDIAN|SLIME|WIZARD)");
    if (boss != null)
    {
        vars.HasKilledBoss = true;
        return settings["boss_" + boss];
    }
}

reset
{
    var l = current.Line;
	
	if (old.Line == l || l == null) return;

    
    //
	//if (vars.TryMatch(l, "PLAYTIME:").Success)
	if (l.Contains("PLAYTIME:")){
		vars.HasKilledBoss = false;
        return settings["resetDeath"];
    }
}

exit
{
    vars.Reader.Close();
}

shutdown
{
    vars.Reader.Close();
}