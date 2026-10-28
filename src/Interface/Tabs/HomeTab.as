class HomePageTab : Tab {
    string GetLabel() override { return Icons::Home; }

    vec4 GetColor() override { return pluginColorVec; }

    void RenderHome () {
        if (UI::RedButton(Icons::Heart + " \\$zManiaExchange")) OpenBrowserURL("https://mania.exchange/");
        
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(8, 4));
        UI::AlignTextToFramePadding();
        UI::Text("Follow the ManiaExchange network on");
        UI::SameLine();
        if (UI::Button(Icons::Facebook + " Facebook")) OpenBrowserURL("https://facebook.com/maniaexchange/");
        UI::SameLine();
        if (UI::Button(Icons::YoutubePlay + " YouTube")) OpenBrowserURL("https://youtube.com/maniaexchangetracks/");
        UI::SameLine();
        if (UI::Button(Icons::DiscordAlt + " Discord")) OpenBrowserURL("https://discord.mania.exchange/");
        UI::PopStyleVar(1);

        UI::Separator();

        auto executingPlugin = Meta::ExecutingPlugin();
        UI::Text(pluginColor + Icons::Plug);
        UI::SameLine();
        UI::Text("Plugin");
        UI::Text("Made by \\$777" + executingPlugin.Author + " (forked from Greep's ManiaExchange plugin)");
        UI::Text("Version \\$777" + executingPlugin.Version);
        UI::Text("Plugin ID \\$777" + executingPlugin.ID);
        UI::Text("Site ID \\$777" + executingPlugin.SiteID);
        UI::Text("Type \\$777" + changeEnumStyle(tostring(executingPlugin.Type)));
        if (IsDevMode()) {
            UI::SameLine();
            UI::Text("\\$777(\\$f39"+Icons::Code+" \\$777Dev mode)");
        }
        bool dllLoaded = ixEditor.clickFun !is null && ixEditor.mousePosFun !is null;
        UI::Text("Automated item imports " + (dllLoaded ? '\\$0f0' + Icons::Check : '\\$f00' + Icons::Times));
        if(UI::IsItemHovered()) {
            UI::BeginTooltip();
            if(dllLoaded) {
                UI::Text("This plugin has loaded the required DLL to automatically import items.");
            } else {
                UI::Text("This plugin does not have the required DLL to automatically import items.");
                UI::Text("2 user clicks are required to import each item.");
            }
            UI::EndTooltip();
        }
        if (UI::Button(Icons::Kenney::GithubAlt + " GitHub")) OpenBrowserURL(repoURL);
        UI::SameLine();
        if (UI::Button(Icons::Heartbeat + " Plugin Home")) OpenBrowserURL("https://openplanet.nl/files/" + executingPlugin.SiteID);
        
        UI::Separator();
        UI::Text("\\$f39" + Icons::Heartbeat);
        UI::SameLine();
        UI::Text("Openplanet");
        UI::Text("Version \\$777" + Meta::OpenplanetBuildInfo());
    }

    void Render() override {
        float width = (UI::GetWindowSize().x * 0.35) * 0.5;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        IfaceRender::Image("https://images.mania.exchange/logos/ix/square_sm.png", int(width));

        UI::EndChild();
        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Description");
        UI::PushFont(Fonts::fontTitle);
        UI::Text("Welcome to " + pluginName);
        UI::PopFont();
        UI::PushFont(Fonts::fontHeader2);
        UI::TextDisabled("Select one of the tabs to begin.");
        UI::PopFont();

        UI::Separator();

        RenderHome();
        UI::EndChild();
    }
};
