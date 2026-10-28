// TODO:
// ----------- [ higher priority ] -----------
// ----------- [ low priority ] -----------
// make info button in itemrow/itemsetrow fully right if import button isn't there
// add tabs for top (items/sets) / (week/month)
// make tags clickable
// make author clickable
// add visit set button in item row
// add padding to "loading" text on item list page
// click on item/set id to open browser with ix page
// setting to use downloads instead of score or likes as a metric
// add import/update item from file functionality (update with hotkey?)
// ----------- [ not possible (yet) ] -----------
// Support blocks


IXEditor@ ixEditor = null;

void Main() {
    Fonts::Load();
    @ixEditor = IXEditor();
    startnew(IX::GetAllItemTags);
    // for dev:
    // sleep(100);
    // downloader.Check('set', 11197);
    // ixMenu.AddTab(ItemSetTab(11269), true);
    // ixMenu.AddTab(ItemSetTab(11273), true);
    // ixMenu.AddTab(ItemTab(6033), true);
}

void Render() {
    if(ixEditor !is null)
        ixEditor.Render();
}

void RenderMenu() {
    if(!Fonts::loaded) return;
    if(UI::MenuItem(nameMenu + (IX::APIDown ? " \\$f00"+Icons::Server : ""), "", ixMenu.isOpened)) {
        if (IX::APIDown) {
            Dialogs::Message("\\$f00" + Icons::Times + " \\$zSorry, " + pluginName + " is not responding.\nReload the plugin to try again.");
        } else {
            ixMenu.isOpened = !ixMenu.isOpened;
        }
    }
}

void RenderMenuMain() {
    if(!Fonts::loaded) return;
    if(UI::BeginMenu(nameMenu + (IX::APIDown ? " \\$f00"+Icons::Server : ""))) {
        if (!IX::APIDown) {
            if(UI::MenuItem(pluginColor + Icons::WindowMaximize+"\\$z Open " + shortMXName + " menu", "", ixMenu.isOpened)) {
                ixMenu.isOpened = !ixMenu.isOpened;
            }
        } else {
            UI::TextDisabled("\\$f00" + Icons::Server + " \\$z" + shortMXName + " is down!");
            UI::TextDisabled("Consider to check your internet connection.");
            UI::TextDisabled("Reload the plugin to try again.");
        }
        UI::Separator();
         if (UI::BeginMenu(pluginColor+Icons::InfoCircle + " \\$zAbout")){
            if (UI::BeginMenu(pluginColor+Icons::KeyboardO + " \\$zContact")){
                if (UI::MenuItem(pluginColor+Icons::KeyboardO + " \\$zContact ManiaExchange")) OpenBrowserURL("https://" + MXURL + "/messaging/compose/11");
                if (UI::MenuItem(Icons::Github + " Plugin creator's GitHub")) OpenBrowserURL("https://github.com/RuurdBijlsma");
                UI::EndMenu();
            }
            UI::Separator();
            if (UI::MenuItem(pluginColor+Icons::Heart + " \\$zSupport ManiaExchange")) OpenBrowserURL("https://trackmania.exchange/support");
            if (UI::MenuItem(pluginColor+Icons::Facebook + " \\$zManiaExchange on Facebook")) OpenBrowserURL("https://facebook.com/maniaexchange/");
            if (UI::MenuItem(pluginColor+Icons::YoutubePlay + " \\$zManiaExchange on YouTube")) OpenBrowserURL("https://youtube.com/maniaexchangetracks/");
            if (UI::MenuItem(pluginColor+Icons::DiscordAlt + " \\$zManiaExchange on Discord")) OpenBrowserURL("https://discord.mania.exchange/");
            UI::EndMenu();
         }
        if (UI::BeginMenu("\\$f90"+Icons::CircleThin + " \\$zAdvanced")){
            UI::TextDisabled("Actual Repository URL: ");
            UI::TextDisabled(MXURL);
            if (UI::MenuItem(pluginColor+Icons::ExternalLink + " \\$zOpen "+pluginName+" in browser")) OpenBrowserURL("https://" + MXURL);
            UI::EndMenu();
        }
        if(UI::MenuItem("\\$f33"+Icons::Github + " \\$zReport a plugin issue")) OpenBrowserURL("https://github.com/RuurdBijlsma/tm-item-exchange/issues");
        UI::EndMenu();
    }
}

void RenderInterface(){
    if(!Fonts::loaded) return;
    ixMenu.Render();
    Dialogs::RenderInterface();
}

string changeEnumStyle(const string &in enumName){
    string str = enumName.SubStr(enumName.IndexOf(":") + 1);
    str = str.Replace("_", " ");
    return str;
}