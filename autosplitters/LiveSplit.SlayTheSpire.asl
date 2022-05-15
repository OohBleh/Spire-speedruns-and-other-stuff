/* Autosplitter v1.0 2018-04-09
SlayTheSpire Autosplitter by ClownFiesta AKA FresherDenimAll
Hosted on https://github.com/ClownFiesta/AutoSplitters

Please notify the author before attempting to publish a new AutoSplitter for the game,
I might be working on a new version already locally.

Honorable mention: Phantom. He created the previous Autosplitter for the game which you can see at:
https://github.com/Phxntxm/Slay-The-Spire-Autosplitter
 */

state("javaw")
{

}

state("SlayTheSpire")
{

}

startup
{
	settings.Add("oneChar", true, "1-character mode (splits on every boss kill or skip)");
	settings.Add("deathReset", true, "resets on death", "oneChar");
	settings.Add("fourChar", false, "4-character mode (splits on every Act III boss kill or skip)");
	
	settings.Add("ascClimb", false, "ascension climb");
	settings.Add("allAchieves", false, "all achievements");
	settings.Add("powerSplit", false, "split for Powerful achievement", "allAchieves");
	settings.Add("neonSplit", false, "split for Neon achievement", "allAchieves");
	
	bool bossKilled = false;
}



init
{
    //Get the path for the logs
    
	if (game.ProcessName == "javaw"){
		vars.stsLogPath =  System.IO.Directory.GetParent(modules.First().FileName).FullName + "\\..\\..\\sendToDevs\\logs\\SlayTheSpire.log";
	} else{
		vars.stsLogPath =  System.IO.Directory.GetParent(modules.First().FileName).FullName + "\\sendToDevs\\logs\\SlayTheSpire.log";
	}
	
	
	//vars.stsLogPath =  System.IO.Directory.GetParent(modules.First().FileName).FullName + "\\..\\..\\sendToDevs\\logs\\SlayTheSpire.log";
	
    //Open the logs and set the position to the end of the file
    vars.reader = new StreamReader(new FileStream(vars.stsLogPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.reader.BaseStream.Seek(0, SeekOrigin.End);
    vars.lastPointerPosition = vars.reader.BaseStream.Position;
    //Set the command to "UPDATE"
    vars.command = "UPDATE";
}

update
{

    if (vars.reader.BaseStream.Length == vars.lastPointerPosition){ //If the logs haven't changed, skip the rest of the code (update, reset, split, start, etc.). We place it first to lessen the load on the computer
        return false;
    } else if (vars.reader.BaseStream.Length < vars.lastPointerPosition){ //If the logs have been reset, then place the pointer at the end and update vars.lastPointerPosition and skip the rest of the code.
        vars.reader.BaseStream.Seek(0, SeekOrigin.End);
        vars.lastPointerPosition = vars.reader.BaseStream.Position;
        return false;
    }

    string line = "";
    while((line = vars.reader.ReadLine()) != null){ //Read the log until its end
        //Updates vars.lastPointerPosition to its new position.
        vars.lastPointerPosition = vars.reader.BaseStream.Position;
        
        //Changes the value of vars.command depending on the content of line and returns true if a command needs to be issued.
        if(line.Contains("Generating seeds")){
            vars.command = "START";
            return true;
        } else if (timer.CurrentPhase == TimerPhase.Running){
			
			// listen for a boss kill
			if (settings["oneChar"]){
				if (System.Text.RegularExpressions.Regex.IsMatch(line, @"(Hard Unlock: )(GUARDIAN|GHOST|SLIME|CHAMP|AUTOMATON|COLLECTOR|CROW|DONUT|WIZARD)")){
					vars.command = "SPLIT";
					vars.bossKilled = true;
					return true;
				}
				
				else if(line.Contains("TreasureRoomBoss") || line.Contains("VictoryRoom")){
					if (vars.bossKilled){
						vars.bossKilled = false;
					} else{
						vars.command = "SPLIT";
					}
					return true;
				}
				
				else if (System.Text.RegularExpressions.Regex.IsMatch(line, @"(PLAYTIME:)")){
					if (vars.deathReset){
						vars.command = "RESET";
					}
					return true;
				}
			}
			else if (settings["fourChar"]){
				if (System.Text.RegularExpressions.Regex.IsMatch(line, @"(Hard Unlock: )(CROW|DONUT|WIZARD)")){
					vars.command = "SPLIT";
					vars.bossKilled = true;
					return true;
				}
				
				if(line.Contains("VictoryRoom")){
					if (vars.bossKilled){
						vars.bossKilled = false;
					} else{
						vars.command = "SPLIT";
					}
					return true;
				}
			} else if (settings["ascClimb"]){
				if(line.Contains("Generating seeds")){
					vars.command = "START";
					return true;
				} else if (line.Contains("ASCENSION LEVEL IS NOW: ")){
					vars.command = "SPLIT";
					return true;
				} else if (System.Text.RegularExpressions.Regex.IsMatch(line, @"(Achievement Unlocked: )(RUBY|EMERALD|SAPPHIRE|AMETHYST|ASCEND_20)")){
					vars.command = "SPLIT";
					return true;
				}
			} else if (settings["allAchieves"]){
				if(line.Contains("UPDATING DEFAULT SLOT: ")){
					vars.command = "START";
					return true;
				} else if (line.Contains("ASCENSION LEVEL IS NOW: ")){
					vars.command = "SPLIT";
					return true;
				} else if (settings["powerSplit"] && System.Text.RegularExpressions.Regex.IsMatch(line, @"(Achievement Unlocked: )(POWERFUL)")){
					vars.command = "SPLIT";
					return true;
				} else if (settings["neonSplit"] && System.Text.RegularExpressions.Regex.IsMatch(line, @"(Achievement Unlocked: )(NEON)")){
					vars.command = "SPLIT";
					return true;
				} else if (System.Text.RegularExpressions.Regex.IsMatch(line, @"(Achievement Unlocked: )(EMERALD|SAPPHIRE|AMETHYST|LUCKY_DAY|EMERALD_PLUS|SAPPHIRE_PLUS|AMETHYST_PLUS|ASCEND_20)")){
					vars.command = "SPLIT";
					return true;
				}
			}
        }
	}
}

reset
{
    if (vars.command == "RESET"){
        vars.command = "UPDATE";
		vars.bossKilled = false;
        return true;
    }
}

split
{
    if (vars.command == "SPLIT"){
        vars.command = "UPDATE";
        return true;
    }
}

start
{
    if (vars.command == "START"){
		vars.bossKilled = false;
        vars.command = "UPDATE";
        return true;
    }
}

exit
{   
    // Resets the timer if the game closes (either from a bug or manually)
    new TimerModel() { CurrentState = timer }.Reset();
    vars.reader.Close();
    vars.lastPointerPosition = 0;
}

shutdown
{
    // Closing the reader (Only useful when you close LiveSplit before closing SlayTheSpire)
    vars.reader.Close();
}

isLoading
{
    // Blank isLoading to avoid any warnings
}

gameTime
{
    // Blank gameTime to avoid any warnings
}
