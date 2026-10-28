namespace IfaceRender {
    int HoverImage(const string &in url, int width = 0, int height =  0) {
        auto img = Images::CachedFromURL(url);
        if(height == 0 && width == 0) {
            warn("Width and height can't both be 0, aborting");
            return 0;
        }
        int w = 0;
        int h = 0;
        if (img.m_texture !is null){
            vec2 thumbSize = img.m_texture.GetSize();
            if(width == 0) {
                // calculate width
                w = int(thumbSize.x / (thumbSize.y / height));
                h = height;
            } else {
                // calculate height
                w = width;
                h = int(thumbSize.y / (thumbSize.x / width));
            }
            UI::Image(img.m_texture, vec2(w, h));
            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                UI::Image(img.m_texture, vec2(
                    Display::GetWidth() * 0.4,
                    thumbSize.y / (thumbSize.x / (Display::GetWidth() * 0.4))
                ));
                UI::EndTooltip();
            }
        } else {
            UI::Text(IfaceRender::GetHourGlass() + " Loading");
            if(width == 0) {
                UI::Dummy(vec2(height, height - 16));
                w = height;
                h = height;
            } else {
                UI::Dummy(vec2(width, width - 16));
                w = height;
                h = height;
            }
        }
        if(width == 0)
            return w;
        return h;
    }

    void Image(const string &in url, int width) {
        auto img = Images::CachedFromURL(url);
        if(img.m_texture !is null){
            vec2 thumbSize = img.m_texture.GetSize();
            UI::Image(img.m_texture, vec2(
                width,
                thumbSize.y / (thumbSize.x / width)
            ));
        } else {
            UI::Dummy(vec2(width, width));
        }
    }

    void SimpleTableRow(string[] text){
        UI::TableNextRow();
        for(uint i = 0; i < text.Length; i++) {
            if(i == 0) UI::PushFont(Fonts::fontBold);
            UI::TableSetColumnIndex(i);
            UI::Text(text[i]);
            if(i == 0) UI::PopFont();
        }
    }

    void TabHeader(const string &in header){
        UI::BeginTabBar(header);
        UI::BeginTabItem(header);
        UI::EndTabItem();
        UI::EndTabBar();
    }

    vec4 noTagsColor = vec4(1, 1, 1, .01);
    void Tags(IX::ItemTag@[] tags) {
        if (tags.Length == 0){
            IfaceRender::Tag("No tags", noTagsColor);
        }
        else {
            for (uint i = 0; i < tags.Length; i++) {
                if(i != 0) {
                    UI::SameLine();
                }
                if(UI::GetCursorPos().x + 75 > UI::GetWindowSize().x) {
                    UI::NewLine();
                }
                IfaceRender::ItemTag(tags[i]);
            }
        }
    }

    string GetHourGlass(){
        int HourGlassValue = Time::Stamp % 3;
        return (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
    }


    void ImportButton(EImportType importType, const ref &in data, const string &in buttonId, bool showText = false, bool transparentButton = false) {
        if(!Permissions::OpenAdvancedMapEditor()) {
            UI::NewLine();
            return;
        }

        if(importType == EImportType::Item) {
            auto item = cast<IX::Item@>(data);
            if(item.IsStoredLocally) {
                string buttonText = Icons::Refresh + (showText ? " Update item" : "") + "##" + buttonId;
                if(ixMenu.isInEditor && UI::RedButton(buttonText)) {
                    IO::Delete(item.GetCachePath());
                    IO::Delete(item.GetDestinationPath());
                    item.IsStoredLocally = false;
                    startnew(ImportFunctions::Item, data);
                } 
                if(!ixMenu.isInEditor) {
                    UI::NewLine();
                }
                return;
            }
        }

        bool loading = ixEditor.isImporting;

        string icon = loading ? GetHourGlass() : Icons::Download;

        string extraText = "";
        if(!loading && showText) {
            extraText += " Import into editor";
        } else if(loading && showText) {
            extraText += " Importing...";
        }
        extraText += "##" + buttonId;

        if(loading) UI::BeginDisabled();
        if((loading || ixMenu.isInEditor) && (transparentButton ? UI::TransparentButton(icon + extraText) : UI::CyanButton(icon + extraText))) {
            if(importType == EImportType::Item) {
                startnew(ImportFunctions::Item, data);
            } else if(importType == EImportType::Tree) {
                startnew(ImportFunctions::Tree, data);
            }
        } 
        
        if(!loading && !ixMenu.isInEditor) {
            UI::NewLine();
        }
        if(ixMenu.isInEditor && importType == EImportType::Tree && UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::Text("Import part of set");
            UI::EndTooltip();
        }
        if(loading) UI::EndDisabled();
    }

    void ItemType(IX::Item@ item) {
        if(item.Type == EItemType::Ornament){
            UI::Text(Icons::Tree);
        } else if(item.Type == EItemType::Block){
            UI::Text(Icons::Cube);
        } else {
            UI::Text(Icons::Question);
        }
    }
}

enum EImportType {
    Item, Tree
};

namespace ImportFunctions {
    void DownloadItems(ref@ itemsRef) {
        auto items = cast<IX::Item@[]>(itemsRef);
        ixEditor.ImportItems(items, false, Setting_OverwriteWhenImporting);
        UI::ShowNotification("Downloaded items! restart the game to see them in the editor");
    }

    void Item(ref@ itemRef) {
        auto item = cast<IX::Item@>(itemRef);
        ixEditor.ImportItems({item}, true, Setting_OverwriteWhenImporting);
        UI::ShowNotification("Imported item!");
    }

    void Tree(ref@ dictRef) {
        auto tree = cast<dictionary@>(dictRef);
        auto items = IX::TreeToArray(tree);
        ixEditor.ImportItems(items, true, Setting_OverwriteWhenImporting);
    }
}