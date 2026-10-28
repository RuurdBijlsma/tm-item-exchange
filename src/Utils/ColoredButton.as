namespace UI {
    bool TransparentButton(const string &in text) {
        UI::PushStyleColor(UI::Col::Button, vec4(1, 1, 1, 0));
        UI::PushStyleColor(UI::Col::ButtonHovered, vec4(1, 1, 1, 0.05));
        UI::PushStyleColor(UI::Col::ButtonActive, vec4(1, 1, 1, 0.2));
        bool button = UI::Button(text);
        UI::PopStyleColor(3);
        return button;
    }

    bool RedButton(const string &in text) { return UI::ButtonColored(text, 0.0f); }
    bool GreenButton(const string &in text) { return UI::ButtonColored(text, 0.33f); }
    bool OrangeButton(const string &in text) { return UI::ButtonColored(text, 0.1f); }
    bool CyanButton(const string &in text) { return UI::ButtonColored(text, 0.5f); }
    bool PurpleButton(const string &in text) { return UI::ButtonColored(text, 0.8f); }
    bool RoseButton(const string &in text) { return UI::ButtonColored(text, 0.9f); }
}
