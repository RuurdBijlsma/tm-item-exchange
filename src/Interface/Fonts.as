namespace Fonts {
    Resources::Font@ fontTitle = null;
    Resources::Font@ fontRegularHeader = null;
    Resources::Font@ fontBold = null;
    Resources::Font@ fontHeader = null;
    Resources::Font@ fontHeader2 = null;
    bool loaded = false;

    void Load() {
        Resources::Font@ fontTitle = Resources::GetFont("Oswald-Regular.ttf", 32);
        Resources::Font@ fontRegularHeader = Resources::GetFont("Oswald-Regular.ttf", 32);
        Resources::Font@ fontBold = Resources::GetFont("DroidSans-Bold.ttf", 16);
        Resources::Font@ fontHeader = Resources::GetFont("DroidSans-Bold.ttf", 24);
        Resources::Font@ fontHeader2 = Resources::GetFont("DroidSans-Bold.ttf", 18);
        loaded = true;
    }
}