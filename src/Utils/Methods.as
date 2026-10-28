string[] BoolsToStrings(bool[] input){
    string[] output = {};
    for(uint i = 0; i < input.Length; i++)
        output.InsertLast(tostring(input[i]));
    return output;
}

string[] IntsToStrings(int[] input){
    string[] output = {};
    for(uint i = 0; i < input.Length; i++)
        output.InsertLast(tostring(input[i]));
    return output;
}

string SecondsDifferenceToString(int seconds, bool short = true) {
    if(seconds < 60) {
        return seconds + (short ? "s" : " second" + (seconds == 1 ? "" : "s"));
    }
    int minutes = int(Math::Round(float(seconds) / 60));
    if(minutes < 60) {
        return minutes + (short ? "m" : " minute" + (minutes == 1 ? "" : "s"));
    }
    int hours = int(Math::Round(float(seconds) / 3600));
    if(hours < 24) {
        return hours + (short ? "h" : " hour" + (hours == 1 ? "" : "s"));
    }
    int days = int(Math::Round(float(seconds) / 86400));
    if(days < 31) {
        return days + " day" + (days == 1 ? "" : "s");
    }
    int months = int(Math::Round(float(seconds) / 86400 / 30.437));
    if(months < 12) {
        return months + " month" + (months == 1 ? "" : "s");
    }
    int years = int(Math::Round(float(seconds) / 86400 / 365.25));
    return years + " year" + (years == 1 ? "" : "s");
}

int[] monthDurations = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
// not accurate, but good enough
int DateTimeSubtract(const Time::Info &in dateTime1, const Time::Info &in dateTime2) { 
    int years = dateTime1.Year - dateTime2.Year;
    int months = dateTime1.Month - dateTime2.Month;
    int days = dateTime1.Day - dateTime2.Day;
    int hours = dateTime1.Hour - dateTime2.Hour;
    int minutes = dateTime1.Minute - dateTime2.Minute;
    int seconds = dateTime1.Second - dateTime2.Second;
    int daysDifference = int(years * 365.25 + days);
    if(months < 0)
        for(int i = dateTime1.Month - 1; i < dateTime2.Month - 1; i++) 
            daysDifference -= monthDurations[i];
    else
        for(int i = dateTime2.Month - 1; i < dateTime1.Month - 1; i++) 
            daysDifference += monthDurations[i];
    
    return daysDifference * 3600 * 24 + hours * 3600 + minutes * 60 + seconds;
}

string DateTimeToString(const Time::Info &in dateTime) {
    return dateTime.Year + "-" + dateTime.Month + "-" + dateTime.Day + " " + dateTime.Hour + ":" + dateTime.Minute + ":" + dateTime.Second;
}

Time::Info ParseDateTime(const string &in dateTime) {
    auto info = Time::Info();
    auto matches = Regex::Search(dateTime, "(\\d{4})-([01]\\d)-([0-3]\\d)T([0-2]\\d):([0-5]\\d):([0-5]\\d)");
    if(matches.Length != 7) {
        info.Year = 1970;
        info.Month = 1;
        info.Day = 1;
        info.Hour = 0;
        info.Minute = 0;
        info.Second = 0;
        return info;
    }
    for(uint i = 1; i < matches.Length; i++) {
        if(i == 1) info.Year = Math::Clamp(Text::ParseInt(matches[i]), 1, 5000);
        if(i == 2) info.Month = Math::Clamp(Text::ParseInt(matches[i]), 1, 12);
        if(i == 3) info.Day = Math::Clamp(Text::ParseInt(matches[i]), 1, 31);
        if(i == 4) info.Hour = Math::Clamp(Text::ParseInt(matches[i]), 0, 24);
        if(i == 5) info.Minute = Math::Clamp(Text::ParseInt(matches[i]), 0, 59);
        if(i == 6) info.Second = Math::Clamp(Text::ParseInt(matches[i]), 0, 59);
    }
    return info;
}

bool IsDevMode(){
    return Meta::ExecutingPlugin().Type == Meta::PluginType::Folder;
}

string GetItemsFolder() {
    return IO::FromUserGameFolder("items/");
}

// Windows rejects these characters in file and folder names. Set names,
// usernames and the directory structure inside a set come straight from the
// API, so they can contain them (e.g. "Tiny Blocks - DecoWall (4/4: Slopes)",
// where the leftover ':' makes IO::CreateFolder fail with
// "The filename, directory name, or volume label syntax is incorrect").
string SanitizePathComponent(const string &in name) {
    string result = name;
    string[] invalidChars = {"\\", "/", ":", "*", "?", "\"", "<", ">", "|"};
    for(uint i = 0; i < invalidChars.Length; i++)
        result = result.Replace(invalidChars[i], "-");
    // Windows silently strips trailing dots and spaces, which would make the
    // folder name on disk differ from the path checked afterwards.
    while(result.Length > 0 && (result.EndsWith(".") || result.EndsWith(" ")))
        result = result.SubStr(0, result.Length - 1);
    if(result.Length == 0)
        result = "_";
    return result;
}

// Sanitizes every component of a relative folder path (components may be
// separated by either kind of slash). Returns it with forward slashes and
// without leading or trailing separators.
string SanitizeRelativeFolder(const string &in path) {
    string normalized = path.Replace("\\", "/");
    auto parts = normalized.Split("/");
    string result = "";
    for(uint i = 0; i < parts.Length; i++) {
        auto part = parts[i];
        if(part.Length == 0 || part == "." || part == "..")
            continue;
        if(result.Length > 0)
            result += "/";
        result += SanitizePathComponent(part);
    }
    return result;
}