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

init
{
    //Get the path for the logs
    vars.stsLogPath =  System.IO.Directory.GetParent(modules.First().FileName).FullName + "\\..\\..\\sendToDevs\\logs\\SlayTheSpire.log";
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
        } else if (timer.CurrentPhase == TimerPhase.Running & System.Text.RegularExpressions.Regex.IsMatch(line, @"(Hard Unlock: )(CROW|DONUT|WIZARD)")){
            vars.command = "SPLIT";
            return true;
        } else if (System.Text.RegularExpressions.Regex.IsMatch(line, @"(PLAYTIME:)")){
            vars.command = "RESET";
            return true;
            }
        }

}

reset
{
    if (vars.command == "RESET"){
        vars.command = "UPDATE";
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
