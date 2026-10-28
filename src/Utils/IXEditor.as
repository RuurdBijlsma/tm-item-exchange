class RequestItemTuple {
    Net::HttpRequest@ request = null;
    IX::Item@ item = null;
    RequestItemTuple(Net::HttpRequest@ request, IX::Item@ item) {
        @this.request = request;
        @this.item = item;
    }
};

class IXEditor {
    Import::Library@ lib = null;
    Import::Function@ clickFun = null;
    Import::Function@ mousePosFun = null;
    bool isImporting = false;
    bool isDownloading = false;
    string downloadFolder = '';
    string statusText = "";
    string subText = "";
    bool importCanceled = false;

    IXEditor() {
        @lib = GetZippedLibrary("lib/libclick.dll");
        if(lib !is null) {
            @clickFun = lib.GetFunction("clickPos");
            @mousePosFun = lib.GetFunction("moveMouse");
        }

        auto opFolder = IO::FromDataFolder('');
        downloadFolder = opFolder + '/IX/';
        if(!IO::FolderExists(downloadFolder))
            IO::CreateFolder(downloadFolder);
    }

    bool WaitForImport() {
        int waitTime = 0;
        while(isImporting) { 
            waitTime++;
            yield();
            warn("Trying to import an item while another is being imported!");
            // timeout after 5s
            if(waitTime > 500){
                UI::ShowNotification("Couldn't import item, importer is busy.");
                return false;
            }
        }
        return true;
    }

    void CreateFolderRecursive(string basePath, string createPath){
        string separator = "/";
        basePath.Replace("\\", separator);
        createPath.Replace("\\", separator);
        // remove double //
        while(basePath.Contains(separator + separator)){
            basePath = basePath.Replace(separator + separator, separator);
        }
        while(createPath.Contains(separator + separator)){
            createPath = createPath.Replace(separator + separator, separator);
        }
        // Format path to the following template
        // basePath: C://Users/Ruurd/ (ends with separator)
        // createPath: OpenplanetNext/Plugins/lib (no separator at start or end)
        if(basePath.EndsWith(separator)){
            basePath = basePath.SubStr(0, basePath.Length - 1);
        }
        if(createPath.StartsWith(separator)) {
            createPath = createPath.SubStr(1);
        }
        if(createPath.EndsWith(separator)) {
            createPath = createPath.SubStr(0, createPath.Length - 1);
        }
        auto parts = createPath.Split(separator);

        string path = basePath;
        for(uint i = 0; i < parts.Length; i++) {
            if(!IO::FolderExists(path + separator + parts[i])) {
                IO::CreateFolder(path + separator + parts[i]);
            }
            path += separator + parts[i];
        }
    }

    bool CleanCanceledImport() {
        isDownloading = false;
        isImporting = false;
        subText = "";
        statusText = "";
        importCanceled = false;
        return false;
    }

    bool DownloadItems(IX::Item@[] items) {
        int downloadsFinished = 0;
        int downloadsTotal = items.Length;
        isDownloading = true;
        RequestItemTuple@[] requests = {};
        for(uint i = 0; i < items.Length; i++) {
            auto item = items[i];
            auto itemFolder = item.GetRelativeFolder();
            CreateFolderRecursive(downloadFolder, itemFolder);

            if(!IO::FileExists(item.GetCachePath())) {
                auto url = "https://" + MXURL + "/item/download/" + item.ID;                
                auto request = Net::HttpGet(url);
                requests.InsertLast(RequestItemTuple(request, item));
            } else {
                // file already exists in downloads cache, increment counter
                downloadsFinished++;
            }
        }

        int totalRequestsCount = items.Length;
        // Wait for all downloads to complete
        while(true) {
            if(importCanceled)
                return CleanCanceledImport();
            statusText = "Downloading [" + downloadsFinished + " / " + totalRequestsCount + "]";
            for(int i = int(requests.Length) - 1; i >= 0; i--) {
                auto ri = requests[i];
                if(!ri.request.Finished())
                    continue;
                downloadsFinished++;
                requests.RemoveAt(i);
                auto code = ri.request.ResponseCode();
                if(code < 200 || code >= 300) {
                    warn("Error making request to '" + ri.request.Url + "' error code: " + code);
                    continue;
                }
                ri.request.SaveToFile(ri.item.GetCachePath());
            }
            if(downloadsFinished == downloadsTotal) 
                break;
            yield();
        }

        statusText = "";
        isDownloading = false;
        return true;
    }

    bool ImportItems(IX::Item@[] items, bool intoEditor = true, bool overwrite = true) {
        if(!WaitForImport()) return false;
        isImporting = true;

        subText = "Press V to cancel import";
        if(!DownloadItems(items)) return false;

        for(uint i = 0; i < items.Length; i++) {
            auto item = items[i];
            auto itemFolder = item.GetRelativeFolder();
            if(!overwrite && IO::FileExists(item.GetDestinationPath())){
                // file already exists in items folder
                continue; 
            }
            string desiredItemLocation = itemFolder + item.FileName;
            statusText = "Importing [" + (i + 1) + " / " + items.Length + "]";
            if(intoEditor) {
                if(item.Type == EItemType::Block) {
                    UI::ShowNotification("Importing blocks is not supported! Failed to import'" + item.Name + "'.");
                    continue;
                }
                if(LoadItem(item.GetCachePath(), desiredItemLocation)) {
                    item.IsStoredLocally = true;
                } else {
                    UI::ShowNotification("Couldn't import item: " + item.Name);
                }
            } else {
                auto tmItemsFolder = GetItemsFolder();
                CreateFolderRecursive(tmItemsFolder, itemFolder);
                auto toFile = tmItemsFolder + desiredItemLocation;
                CopyFile(item.GetCachePath(), toFile);
            }
            if(importCanceled)
                return CleanCanceledImport();
            yield();
        }

        subText = "";
        statusText = "";
        isImporting = false;
        return true;
    }

    bool YieldAndCheckCancel() {
        if(importCanceled) {
            return true;
        }
        yield();
        return false;
    }

    void EnterCreateNewItemUI(CTrackMania@ app) {
#if MP4
        CGameManiaPlanet@ baseApp = cast<CGameManiaPlanet>(GetApp());
        string base = baseApp.LoadedManiaTitle.BaseTitleId;
#endif
        if(mousePosFun !is null && clickFun !is null) {
            auto screenHeight = Display::GetHeight();
            auto screenWidth = Display::GetWidth();
            // Click screen at position to enter "create new item" UI
            auto xClick = screenWidth / 2;
            auto yClick = screenHeight / 2;
            mousePosFun.Call(xClick, yClick - 2);
            yield();
            mousePosFun.Call(xClick, yClick - 1);
            yield();
            clickFun.Call(true, xClick, yClick);
#if MP4
            yield();
            if (base == "SMStorm") 
            {
                clickFun.Call(true, xClick, yClick);
            } else 
            {
                clickFun.Call(true, xClick, yClick + 30);
            }
#endif
        } else {
            // make user click
            auto maxLoops = 2000; // wait max 20 seconds for user to get to item editor
            while (cast<CGameEditorItem>(app.Editor) is null) {
                DrawText("Click in the map!");
                if(YieldAndCheckCancel() || maxLoops-- <= 0) {
                    UI::ShowOverlay();
                    return;
                }
            }
        }
        UI::ShowOverlay();
    }

    bool EnterEditItemUI(CTrackMania@ app) {
        if(mousePosFun !is null && clickFun !is null) {
            auto screenWidth = Display::GetWidth();
            auto screenHeight = Display::GetHeight();
            auto xClick = screenWidth / 2;
            auto yClick = screenHeight / 2;
            mousePosFun.Call(true, xClick, yClick - 1);
            auto maxLoops = 100; // wait max 1 seconds
            // Click screen until we're in "edit item" UI
            while(true) {
#if MP4
                clickFun.Call(true, xClick, yClick - (maxLoops - 50));
#else
                clickFun.Call(true, xClick, yClick - 2);
#endif
                yield();
                auto editorItem = cast<CGameEditorItem>(app.Editor);
                if(editorItem !is null){
                    UI::ShowOverlay();
                    return true;
                }
                if(maxLoops-- <= 0){
                    UI::ShowOverlay();
                    return false;
                }
            }
        } else {
            // make user click on item
            auto maxLoops = 2000; // wait max 20 seconds for user to get to item editor
            while(cast<CGameEditorItem>(app.Editor) is null) {
                DrawText("Click the new cube!");
                if(YieldAndCheckCancel() || maxLoops-- <= 0) {
                    UI::ShowOverlay();
                    return false;
                }
            }
            UI::ShowOverlay();
            return true;
        }

        return false;
    }

    // gbxLocation: absolute path to item.gbx file
    // desiredItemLocation: relative path where it should be put (relative to Trackmania/Items/)
    bool LoadItem(const string &in gbxLocation, const string &in desiredItemLocation) {
#if TMNEXT
        if(!Permissions::OpenAdvancedMapEditor())
            return false;
#endif
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        auto editor = cast<CGameCtnEditorCommon@>(app.Editor);
        if(editor is null) {
            warn("Editor is null");
            return false;
        }

        if(YieldAndCheckCancel()) return false;
        // Click "create new item" button
        editor.ButtonItemNewModeOnClick();
        
        UI::HideOverlay();

        if(YieldAndCheckCancel()) return false;

        EnterCreateNewItemUI(app);
        if(YieldAndCheckCancel()) return false;

        // Save empty item to file
        auto editorItem = cast<CGameEditorItem>(app.Editor);
        if(editorItem is null) {
            warn("Editor item is null");
            return false;
        }
        editorItem.FileSaveAs();
        
        if(YieldAndCheckCancel()) return false;
        if(YieldAndCheckCancel()) return false;

        int maxUps = 10;
        while(app.BasicDialogs.DialogSaveAs_Path != "") {
            print("Doing hierarchy up, because path = " + app.BasicDialogs.DialogSaveAs_Path);
            app.BasicDialogs.DialogSaveAs_HierarchyUp();
            if(maxUps-- <= 0) {
                warn("Couldn't find item save path.");
                return false;
            }
        }

        app.BasicDialogs.String = desiredItemLocation;
        
        if(YieldAndCheckCancel()) return false;
        app.BasicDialogs.DialogSaveAs_OnValidate();
        
        if(YieldAndCheckCancel()) return false;
        app.BasicDialogs.DialogSaveAs_OnValidate();
        
        if(YieldAndCheckCancel()) return false;
        
        // Exit "create new item" UI
        editorItem.Exit();

        // OVERWRITE ITEM WITH ACTUAL GBX FILE
        
        auto itemLocation = GetItemsFolder() + desiredItemLocation;
        if(!IO::FileExists(itemLocation)) {
            // temp item wasn't created correctly
            warn("Temporary item wasn't created correctly!");
            warn("Item Location: " + itemLocation);
            return false;
        }
        CopyFile(gbxLocation, itemLocation);
        
        // Wait until exited item UI
        while(cast<CGameEditorItem>(app.Editor) !is null){  
            if(YieldAndCheckCancel()) return false;
        }

        // Click "edit item" button
        editor.ButtonItemEditModeOnClick();

        UI::HideOverlay();

        if(YieldAndCheckCancel()) return false;
        if(!EnterEditItemUI(app)) {
            error("ERROR getting to 'edit item' UI");
            return false;
        }

        // Exit edit item UI
        cast<CGameEditorItem>(app.Editor).Exit();

        // Wait until exited item UI
        while(cast<CGameEditorItem>(app.Editor) !is null){  
            if(YieldAndCheckCancel()) return false;
        }

        // undo placing
        editor.PluginMapType.Undo();
        editor.PluginMapType.Undo();

        return true;
    }

    bool CopyFile(const string &in fromFile, const string &in toFile, bool overwrite = true) {
        if(!IO::FileExists(fromFile)){
            warn("fromFile does not exist");
            return false;
        }
        if(!overwrite && IO::FileExists(toFile)){
            warn("toFile already exists, and overwrite is set to false!");
            return false;
        }
        IO::File fromItem(fromFile);
        fromItem.Open(IO::FileMode::Read);
        auto buffer = fromItem.Read(fromItem.Size());
        IO::File toItem(toFile, IO::FileMode::Write);
        toItem.Write(buffer);
        fromItem.Close();
        toItem.Close();
        return true;
    }

    string GetPluginName() {
        auto executingPlugin = Meta::ExecutingPlugin();
        return executingPlugin.Name;
    }

    Import::Library@ GetZippedLibrary(const string &in relativeDllPath) {
        bool testNonAutomated = false;
        if(testNonAutomated) {
            warn("Testing non automated version");
            return null;
        }
        bool preventCache = false;

        auto parts = relativeDllPath.Split("/");
        string fileName = parts[parts.Length - 1];
        const string baseFolder = IO::FromDataFolder('');
        const string dllFolder = baseFolder + 'lib/';
        const string localDllFile = dllFolder + fileName;

        if(!IO::FolderExists(dllFolder)) {
            IO::CreateFolder(dllFolder);
        }

        if(preventCache || !IO::FileExists(localDllFile)) {
            try {
                IO::FileSource zippedDll(relativeDllPath);
                auto buffer = zippedDll.Read(zippedDll.Size());
                IO::File toItem(localDllFile, IO::FileMode::Write);
                toItem.Write(buffer);
                toItem.Close();
            } catch {
                return null;
            }
        }

        return Import::GetLibrary(localDllFile);
    }

    void DrawText(const string &in text, int yOffset = 0, int fontSize = 100) {
        auto screenHeight = Display::GetHeight();
        auto screenWidth = Display::GetWidth();
        auto black = vec4(0, 0, 0, 1);
        auto white = vec4(1, 1, 1, 1);
        nvg::FontFace(Fonts::fontRegularHeader);
        nvg::FontSize(fontSize);
        nvg::FillColor(black);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        nvg::Text(screenWidth / 2 - 2, screenHeight / 4 - 2 + yOffset, text);
        nvg::FillColor(white);
        nvg::Text(screenWidth / 2, screenHeight / 4 + yOffset, text);
    }

    void Render() {
        if((isImporting || isDownloading) && UI::IsKeyPressed(UI::Key::V)) {
            warn("Cancel import!");
            importCanceled = true;
        }
        if(statusText != ''){
            DrawText(statusText, -100, 50);
        }
        if(subText != ''){
            DrawText(subText, 100, 50);
        }
    }
};
