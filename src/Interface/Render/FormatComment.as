namespace IfaceRender {
    enum EPartType { Text, Set, Item };
    class TextPart {
        string value;
        EPartType type;
        TextPart(const string &in value, EPartType type){
            this.value = value;
            this.type = type;
        }
    };

    void IXComment(const string &in comment){
        string formatted = "";

        formatted =
            comment.Replace("[tmx]", "Trackmania\\$075Exchange\\$z")
                .Replace("[mx]", "Mania\\$09FExchange\\$z")
                .Replace("[b]", "")
                .Replace("[/b]", "")
                .Replace("[i]", "")
                .Replace("[/i]", "")
                .Replace("[u]", "__")
                .Replace("[/u]", "__")
                .Replace("[s]", "~~")
                .Replace("[/s]", "~~")
                .Replace("[hr]", "")
                .Replace("[list]", "")
                .Replace("[/list]", "");

        // url regex replacement: https://regex101.com/r/UcN0NN/1
        formatted = Regex::Replace(formatted, "\\[url=([^\\]]*)\\]([^\\[]*)\\[\\/url\\]", "[$2]($1)");

        // img replacement: https://regex101.com/r/WafxU9/1
        formatted = Regex::Replace(formatted, "\\[img\\]([^\\[]*)\\[\\/img\\]", "( Image: $1 )");

        // item replacement: https://regex101.com/r/c9LwXn/1
        formatted = Regex::Replace(formatted, "\\[item\\]([^\\r^\\n]*)", "- $1");

        // quote replacement: https://regex101.com/r/kuI7TO/1
        formatted = Regex::Replace(formatted, "\\[quote\\]([^\\[]*)\\[\\/quote\\]", "> $1");

        // youtube replacement
        formatted = Regex::Replace(formatted, "\\[youtube\\]([^\\[]*)\\[\\/youtube\\]", "[Youtube video]($1)");

        // user replacement
        formatted = Regex::Replace(formatted, "\\[user\\]([^\\[]*)\\[\\/user\\]", "( User ID: $1 )");

        // track replacement
        formatted = Regex::Replace(formatted, "\\[track\\]([^\\[]*)\\[\\/track\\]", "( Track ID: $1 )");
        formatted = Regex::Replace(formatted, "\\[track=([^\\]]*)\\]([^\\[]*)\\[\\/track\\]", "( Track ID: $2 )");

        // align replacement
        formatted = Regex::Replace(formatted, "\\[align=([^\\]]*)\\]([^\\[]*)\\[\\/align\\]", "$2");

        // No support for horizontal lines
        formatted = Regex::Replace(formatted, "-----", " ");

        // Find set and item ids in text formatted like so: [item-12345] [set-123]
        auto itemParts = (formatted + ' ').Split('[item-');
        TextPart@[] itemTextParts = {TextPart(itemParts[0], EPartType::Text)};
        for(uint i = 1; i < itemParts.Length; i++) {
            auto part = itemParts[i];
            string itemID = '';
            string text = part;
            if(part.Contains(']')){
                auto parts = part.Split(']');
                itemID = parts[0];
                if(parts.Length > 1){
                    text = Text::Join(parts, ']').SubStr(itemID.Length + 1);
                } else {
                    text = "";
                }
            }
            if(itemID != '')
                itemTextParts.InsertLast(TextPart(itemID, EPartType::Item));
            itemTextParts.InsertLast(TextPart(text, EPartType::Text));
        }

        TextPart@[] textParts = {};
        for(uint i = 0; i < itemTextParts.Length; i++) {
            if(itemTextParts[i].type == EPartType::Text) {
                // Look for sets in text
                auto setParts = itemTextParts[i].value.Split('[set-');
                textParts.InsertLast(TextPart(setParts[0], EPartType::Text));
                for(uint j = 1; j < setParts.Length; j++) {
                    auto part = setParts[j];
                    string setID = '';
                    string text = part;
                    if(part.Contains(']')){
                        auto parts = part.Split(']');
                        setID = parts[0];
                        if(parts.Length > 1){
                            text = Text::Join(parts, ']').SubStr(setID.Length + 1);
                        } else {
                            text = "";
                        }
                    }
                    if(setID != '')
                        textParts.InsertLast(TextPart(setID, EPartType::Set));
                    textParts.InsertLast(TextPart(text, EPartType::Text));
                }
            } else { 
                textParts.InsertLast(itemTextParts[i]);
            }
        }

        for(uint i = 0; i < textParts.Length; i++) {
            auto part = textParts[i];
            if(part.type == EPartType::Item) {
                auto itemID = Text::ParseInt(part.value);
                auto getStatus = downloader.Check('item', + itemID);
                if(getStatus == EGetStatus::Downloading) {
                    if(UI::GreenButton(IfaceRender::GetHourGlass() + " Item " + part.value)) {
                        ixMenu.AddTab(ItemTab(itemID), true);
                    }
                } else if (getStatus == EGetStatus::Error) {
                    if(UI::GreenButton(Icons::ExclamationTriangle + " Item " + part.value)) {
                        ixMenu.AddTab(ItemTab(itemID), true);
                    }
                } else if (getStatus == EGetStatus::Available) {
                    IfaceRender::ItemBlock(downloader.GetItem(itemID));
                }
            } else if(part.type == EPartType::Set) {
                auto itemSetID = Text::ParseInt(part.value);
                auto getStatus = downloader.Check('set', + itemSetID);
                if(getStatus == EGetStatus::Downloading) {
                    if(UI::OrangeButton(IfaceRender::GetHourGlass() + " Set " + part.value)) {
                        ixMenu.AddTab(ItemSetTab(itemSetID), true);
                    }
                } else if (getStatus == EGetStatus::Error) {
                    if(UI::OrangeButton(Icons::ExclamationTriangle + " Set " + part.value)) {
                        ixMenu.AddTab(ItemSetTab(itemSetID), true);
                    }
                } else if (getStatus == EGetStatus::Available) {
                    IfaceRender::ItemSetBlock(downloader.GetSet(itemSetID));
                } else if (getStatus == EGetStatus::ItemsFailed) {
                    if(UI::OrangeButton(Icons::ExclamationTriangle + " Set " + part.value)) {
                        ixMenu.AddTab(ItemSetTab(itemSetID), true);
                    }
                }
            } else {
                auto trimmedText = part.value.Trim();
                if(trimmedText.Length > 0) 
                    UI::Markdown(trimmedText);
            }
        }
    }
}