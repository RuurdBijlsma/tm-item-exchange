class ItemListTab : Tab {
    Net::HttpRequest@ m_request;
    array<IX::Item@> items;
    uint totalItems = 0;
    bool m_useRandom = false;
    int m_page = 1;

    dictionary@ GetRequestParams() {
        dictionary@ params = {};
        params.Set("api", "on");
        params.Set("limit", "100");
        params.Set("page", tostring(m_page));
        if (m_useRandom) {
            params.Set("random", "1");
            m_useRandom = false;
        }
        return params;
    }

    void StartRequest() {
        print("Start request");
        auto params = GetRequestParams();

        string urlParams = "";
        if (!params.IsEmpty()) {
            auto keys = params.GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                string key = keys[i];
                string value;
                params.Get(key, value);

                urlParams += (i == 0 ? "?" : "&");
                urlParams += key + "=" + Net::UrlEncode(value);
            }
        }

        string url = "https://" + MXURL + "/itemsearch/search" + urlParams;

        if (IsDevMode()) trace("ItemList::StartRequest: " + url);
        @m_request = API::Get(url);
    }

    void CheckStartRequest() {
        // If there's not already a request and the window is appearing, we start a new request
        if (items.Length == 0 && m_request is null && UI::IsWindowAppearing()) {
            StartRequest();
        }
    }

    void CheckRequest() {
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_request !is null && m_request.Finished()) {
            // Parse the response
            string res = m_request.String();
            if (IsDevMode()) trace("ItemList::CheckRequest: " + res);
            @m_request = null;
            auto json = Json::Parse(res);

            // Handle the response
            if (json.HasKey("error")) {
                // HandleErrorResponse(json["error"]);
            } else {
                HandleResponse(json);
            }
        }
    }

    void HandleResponse(const Json::Value &in json) {
        totalItems = json["totalItemCount"];

        auto jsonItems = json["results"];
        for (uint i = 0; i < jsonItems.Length; i++) {
            IX::Item@ item = IX::Item(jsonItems[i]);
            downloader.CacheItem(item);
            items.InsertLast(item);
        }
    }

    void RenderHeader(){}

    void Clear() {
        items.RemoveRange(0, items.Length);
        totalItems = 0;
    }

    void Reload() {
        Clear();
        StartRequest();
    }

    ESearchOrder searchOrder1 = ESearchOrder::UploadDateNewest;
    ESearchOrder searchOrder2 = ESearchOrder::None;
    string[] sortableColumns = {"", "itemName",  "username",  "uploadDate",  "likeCount",  "score",  "fileSize", ""};
    void Render() override {
        CheckRequest();
        RenderHeader();

        if (m_request !is null && items.Length == 0) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
        } else {
            if (items.Length == 0) {
                UI::Text("No items found.");
                return;
            }
            UI::BeginChild("itemList");
            if (UI::BeginTable("List", 8, UI::TableFlags::Sortable | UI::TableFlags::SortMulti)) {
                UI::AlignTextToFramePadding();
                UI::TableSetupColumn("", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoSort, 50);
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch | UI::TableColumnFlags::NoSortDescending, 3);
                UI::TableSetupColumn("By", UI::TableColumnFlags::WidthStretch | UI::TableColumnFlags::NoSortDescending, 1);
                UI::TableSetupColumn(Icons::CalendarO, UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::PreferSortDescending | UI::TableColumnFlags::DefaultSort, 60);
                UI::TableSetupColumn(Icons::Heart, UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::PreferSortDescending, 40);
                UI::TableSetupColumn(Icons::Bolt, UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::PreferSortDescending, 40);
                UI::TableSetupColumn(Icons::Kenney::Save, UI::TableColumnFlags::WidthFixed, 70);
                UI::TableSetupColumn("", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoSort, 70);
                UI::TableSetupScrollFreeze(0, 1); // <-- don't work
                UI::TableHeadersRow();
                
                for(uint i = 0; i < items.Length; i++) {
                    UI::PushID("ResItem" + i);
                    IX::Item@ item = items[i];
                    IfaceRender::ItemRow(item);
                    UI::PopID();
                }

                if (m_request !is null && totalItems > items.Length) {
                    UI::TableNextRow();
                    UI::TableSetColumnIndex(1);
                    UI::Text(Icons::HourglassEnd + " Loading...");
                }
                auto sortSpecs =  UI::TableGetSortSpecs();
                if(sortSpecs.Dirty){
                    searchOrder1 = ESearchOrder::None;
                    searchOrder2 = ESearchOrder::None;
                    for(uint i = 0; i < sortSpecs.Specs.Length; i++) {
                        auto columnSpec = sortSpecs.Specs[i];
                        if(columnSpec.SortOrder >= 2)
                            continue; // only support 2 layers of sort
                        if(columnSpec.SortOrder == 0) {
                            searchOrder1 = GetSearchOrder(columnSpec.ColumnIndex, columnSpec.SortDirection, columnSpec.SortOrder);
                        }
                        if(columnSpec.SortOrder == 1) {
                            searchOrder2 = GetSearchOrder(columnSpec.ColumnIndex, columnSpec.SortDirection, columnSpec.SortOrder);
                        }
                        print("Search order 1: " + tostring(searchOrder1) + ", Search order 2: " + tostring(searchOrder2));
                    }
                    sortSpecs.Dirty = false;
                }
                UI::EndTable();
                if (m_request is null && totalItems > items.Length && UI::GreenButton("Load more")) {
                    m_page++;
                    StartRequest();
                }
            }
            UI::EndChild();
        }
    }

    ESearchOrder GetSearchOrder(int columnIndex, UI::SortDirection direction, int priority) {
        string colName = sortableColumns[columnIndex];
        if(direction == UI::SortDirection::Ascending) {
            if(colName == "itemName") {
                return ESearchOrder::ItemNameAscending;
            }
            if(colName == "username") {
                return ESearchOrder::UploaderIXUsernameAscending;
            }
            if(colName == "likeCount") {
                return ESearchOrder::LikeCountAscending;
            }
            if(colName == "score") {
                return ESearchOrder::ScoreAscending;
            }
            if(colName == "fileSize") {
                return ESearchOrder::FileSizeAscending;
            }
            if(colName == "uploadDate") {
                return ESearchOrder::UploadDateOldest;
            }
            return priority == 0 ? ESearchOrder::UploadDateOldest : ESearchOrder::None;
        } 
        if(direction == UI::SortDirection::Descending) {
            if(colName == "likeCount") {
                return ESearchOrder::LikeCountDescending;
            }
            if(colName == "score") {
                return ESearchOrder::ScoreDescending;
            }
            if(colName == "fileSize") {
                return ESearchOrder::FileSizeDescending;
            }
            if(colName == "uploadDate") {
                return ESearchOrder::UploadDateNewest;
            }
            return priority == 0 ? ESearchOrder::UploadDateNewest : ESearchOrder::None;
        }
        return ESearchOrder::None;
    }
};
