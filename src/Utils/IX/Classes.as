namespace IX {
    void PrintTree(const dictionary &in tree, const string &in indent = ""){
        auto keys = tree.GetKeys();
        for(uint i = 0; i < keys.Length; i++) {

            if(keys[i] == TreeItemsKey) {
                IX::Item@[]@ items;
                if(!tree.Get(keys[i], @items)){
                    warn("Can't get array " + keys[i]);
                    continue;
                }
                print(indent + tostring(i) + ": " +  "array[" + items.Length + "]");
                continue;
            }

            print(indent + tostring(i) + ": " + keys[i]);
            dictionary@ innerTree;
            if(!tree.Get(keys[i], @innerTree)){
                warn("Can't find key " + keys[i]);
                continue;
            }
            
            PrintTree(innerTree, indent + "    ");
        }
    }

    IX::Item@[] TreeToArray(const dictionary &in tree) {
        if(tree is null) {
            warn("Tree to array parameter `tree` can't be null, aborting");
            return {};
        }
        IX::Item@[] items = {};
        auto keys = tree.GetKeys();
        for(uint i = 0; i < keys.Length; i++) {
            if(keys[i] == IX::TreeItemsKey) {
                IX::Item@[]@ childItems;
                if(!tree.Get(keys[i], @childItems)){
                    warn("Can't get array: " + keys[i]);
                    continue;
                }
                for(uint j = 0; j < childItems.Length; j++) {
                    items.InsertLast(childItems[j]);
                }
                continue;
            }

            dictionary@ innerTree;
            if(!tree.Get(keys[i], @innerTree)){
                warn("Can't get child dict: " + keys[i]);
                continue;
            }

            if(innerTree is null){
                warn("Child dict is null! key = " + keys[i]);
                continue;
            }
            
            auto childItems = TreeToArray(innerTree);
            for(uint j = 0; j < childItems.Length; j++) {
                items.InsertLast(childItems[j]);
            }
        }
        return items;
    }

    array<ItemTag@> ParseItemTags(Json::Value json){
        array<ItemTag@> tags = {};
        if (json.GetType() != Json::Type::Null) {
            string tagsString = json;
            string[] jTags = tagsString.Split(',');
            for(uint i=0; i<jTags.Length; i++) {
                bool found = false;
                for(uint j=0; j<m_itemTags.Length; j++) {
                    if(m_itemTags[j].ID == Text::ParseInt(jTags[i])){
                        tags.InsertLast(m_itemTags[j]);
                        found = true;
                        break;
                    }
                }
                if(!found){
                    warn("Could not find tag! " + tagsString + " -> " + jTags[i]);
                }
            }
        }
        return tags;
    }

    // unique key that can't occur naturally in itemset content folder structure
    const string TreeItemsKey = "items_-*-_-*-_.-*-._>_<:()";
    dictionary@ CreateContentTree(IX::Item@[] items) {
        dictionary@ tree = {};
        for(uint i = 0; i < items.Length; i++) {
            auto item = items[i];
            auto parts = item.Directory.Split("\\");
            dictionary@ node = tree;
            // create children if needed
            for(uint j = 0; j < parts.Length; j++) {
                dictionary@ childNode;
                if(node.Get(parts[j], @childNode)) {
                    @node = childNode;
                } else {
                    // if child node doesn't exist yet, create
                    @childNode = {};
                    node[parts[j]] = childNode;
                    @node = cast<dictionary@>(node[parts[j]]);
                    // @node = @childNode;
                }
            }
            // node is now equal to item directory
            IX::Item@[]@ childItems;
            if(!node.Get(TreeItemsKey, @childItems)) {
                @childItems = {};
                node[TreeItemsKey] = childItems;
                @childItems = cast<IX::Item@[]@>(node[TreeItemsKey]);
            }
            childItems.InsertLast(item);
        }

        return tree;
    }

    class Item {
        int64 ID;    //IX Item identifier
        string Name; //Name of item on IX (usually the filename minus the extensions)
        int64 UserID;    //MX UserID of uploader
        string Username; //MX Username of uploader
        string Description;   	//Description of item
        string AuthorLogin;   	//Ingame login of item creator (does not necessarily work for NadeoImporter items)
        string OriginalBlock; 	//For Blocks: The origin block of the custom block
        EItemType Type;   //IX Item Type
        string TypeName; //Name of IX Item Type
        int32 Downloads; //Total downloads of item
        ECollection Collection; //IX Collection/Environment
        string CollectionName;   //Name of IX Collection
        int32 Game;  //IX Game
        string GameName; //Name of IX Game
        int32 Score; //Item Score (Map uses + Awards on Maps)
        string FileName; //Original File Name
        string Uploaded;   //Upload Date
        string Updated;    //Last Update Date
        int64 SetID; //If != 0: Item is uploaded inside a .zip set with the SetID
        string SetName;   	//If SetID != 0: Name of the Set
        string Directory; 	//Directory inside the uploaded Set (if SetID != 0), without leading & trailing slash
        string ZipIndex;  	//CS list of indices for relevant files inside the zip if SetID != 0 (multiple means e.g. that a Shape.Gbx and a Mesh.Gbx file is included)
        bool Visible; //Item is visible and downloadable
        bool Unlisted;    //Item is hidden from search
        bool Unreleased;  //Item is hidden from search and not yet released
        int32 LikeCount; //Amount of Likes that were received for that item
        int32 CommentCount; //Amount of Comments that were received for that item
        int32 FileSize;  //Filesize of item in KB
        array<ItemTag@> Tags = {};  	//CS list of Item tags, see Get Tags method
        bool HasThumbnail;    //Indicates whether or not the item has a custom thumbnail (see Get Item Thumbnail).
        Time::Info uploadedDate;
        Time::Info updatedDate;

        Item(const Json::Value &in json) {
            try {
                ID = json["ID"];
                Name = json["Name"];
                UserID = json["UserID"];
                Username = json["Username"];
                if (json["Description"].GetType() != Json::Type::Null) Description = json["Description"];
                if (json.HasKey("AuthorLogin") && json["AuthorLogin"].GetType() != Json::Type::Null) AuthorLogin = json["AuthorLogin"];
                if (json["OriginalBlock"].GetType() != Json::Type::Null) OriginalBlock = json["OriginalBlock"];
                Type = EItemType(int(json["Type"]));
                TypeName = json["TypeName"];
                Downloads = json["Downloads"];
                Collection = ECollection(int(json["Collection"]));
                CollectionName = json["CollectionName"];
                Game = json["Game"];
                GameName = json["GameName"];
                Score = json["Score"];
                FileName = json["FileName"];
                Uploaded = json["Uploaded"];
                uploadedDate = ParseDateTime(Uploaded);
                Uploaded = Uploaded.Replace("T", " ");
                Updated = json["Updated"];
                updatedDate = ParseDateTime(Updated);
                Updated = Updated.Replace("T", " ");
                SetID = json["SetID"];
                if (json["SetName"].GetType() != Json::Type::Null) SetName = json["SetName"];
                if (json["Directory"].GetType() != Json::Type::Null) Directory = json["Directory"];
                if (json["ZipIndex"].GetType() != Json::Type::Null) ZipIndex = json["ZipIndex"];
                Visible = json["Visible"];
                if (json.HasKey("Unlisted") && json["Unlisted"].GetType() != Json::Type::Null) Unlisted = json["Unlisted"];
                Unreleased = json["Unreleased"];
                LikeCount = json["LikeCount"];
                CommentCount = json["CommentCount"];
                FileSize = json["FileSize"];
                HasThumbnail = json["HasThumbnail"];
                Tags = ParseItemTags(json["Tags"]);
                downloader.SetItemDownloaded(this.ID, IO::FileExists(GetDestinationPath()));
            } catch {
                Name = json["Name"];
                mxError("Error parsing Item: "+Name);
            }
        }

        bool get_IsStoredLocally() {
            return downloader.IsItemDownloaded(this.ID);
        }

        void set_IsStoredLocally(bool value) {
            downloader.SetItemDownloaded(this.ID, value);
        }

        string GetCachePath() {
            return Path::Join(ixEditor.downloadFolder, GetRelativeFolder() + this.FileName);
        }

        string GetDestinationPath() {
            return Path::Join(GetItemsFolder(), GetRelativeFolder() + this.FileName);
        }

        string GetRelativeFolder() {
            string itemFolder = "";
            if(Setting_AddPluginFolder)
                itemFolder += Setting_PluginFolderName + '/';
            if(Setting_AddAuthorFolder)
                itemFolder += this.Username.Replace("/", "-") + '/';
            if(this.SetID != 0 && Setting_AddSetFolder)
                itemFolder += this.SetName.Replace("/", "-") + '/';
            if(this.SetID != 0 && Setting_UseSetDirectoryStructure) {
                if(this.Directory != "")
                    itemFolder += this.Directory.Replace("\\", "/") + '/';
            }
            return itemFolder;
        }
    };

    class ItemSet {
        int64 ID; //ItemExchange Set identifier
        string Name; //Name of the Set
        int64 UserID; //MX User identifier of set uploader
        string Username; //MX Username of set uploader
        string Description; // Description by the Set uploader (Markdown)
        int32 Downloads; //Amount of downloads of this Set
        ECollection Collection; //Collection / Environment of the included items
        string CollectionName; //Name of the Collection / Environment
        EGame Game; //Game this Set is for
        string GameName; //Name of the Game this Set is for
        int32 Score; //Total Item Score of this Set (Item map occurences + awards)
        string FileName; //Name of file (without extension, can only be .zip)
        string Uploaded; //Upload date time
        string Updated; //Update date time
        array<Item@> Items = {}; //	Items included in the Set (for doc, see Get_Item_Info method)
        bool Visible; //Set is visible
        bool Unreleased; //Set is not yet released and hidden from search
        int32 FileSize; //Total FileSize of all included Items
        int32 LikeCount; //Amount of Likes received on the Set
        int32 CommentCount; //Amount of Comments received on the Set
        array<ItemTag@> Tags = {}; //	CS list of tags (see Get_Tags method)
        int32 ImageCount; //Amount of images that are uploaded for the Set
        dictionary@ contentTree = null;
        Time::Info uploadedDate;
        Time::Info updatedDate;

        ItemSet(const Json::Value &in json) {
            try {
                ID = json["ID"];
                Name = json["Name"];
                UserID = json["UserID"];
                Username = json["Username"];
                if (json["Description"].GetType() != Json::Type::Null) Description = json["Description"];
                Downloads = json["Downloads"];
                Collection = ECollection(int(json["Collection"]));
                CollectionName = json["CollectionName"];
                Game = EGame(int(json["Game"]));
                GameName = json["GameName"];
                Score = json["Score"];
                FileName = json["FileName"];
                Uploaded = json["Uploaded"];
                uploadedDate = ParseDateTime(Uploaded);
                Uploaded = Uploaded.Replace("T", " ");
                Updated = json["Updated"];
                updatedDate = ParseDateTime(Updated);
                Updated = Updated.Replace("T", " ");
                Visible = json["Visible"];
                Unreleased = json["Unreleased"];
                FileSize = json["FileSize"];
                LikeCount = json["LikeCount"];
                CommentCount = json["CommentCount"];
                ImageCount = json["ImageCount"];
                Tags = ParseItemTags(json["Tags"]);
                Items = {};
                auto jItems = json["Items"];
                if (jItems.GetType() == Json::Type::Array) {
                    for(uint i = 0; i < jItems.Length; i++)
                        Items.InsertLast(Item(jItems[i]));
                }
                @contentTree = CreateContentTree(Items);
            } catch {
                Name = json["Name"];
                mxError("Error parsing ItemSet: "+Name);
            }
        }
    };

    class ItemTag {
        int ID;
        string Name;
        string Color;
        vec4 VecColor;

        ItemTag(int id, const string &in name, const string &in color) {
            ID = id;
            Name = name;
            Color = color;
            if(Color == "")
                Color = '#333333';
            VecColor = Text::ParseHexColor(Color);
        }

        ItemTag(const Json::Value &in json) {
            try {
                ID = json["ID"];
                Name = json["Name"];
                Color = json["Color"];
                if(Color == "")
                    Color = '#333333';
                VecColor = Text::ParseHexColor(Color);
            } catch {
                Name = json["Name"];
                mxError("Error parsing tag: "+Name);
            }
        }
    };
}