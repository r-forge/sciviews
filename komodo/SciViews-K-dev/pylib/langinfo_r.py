from langinfo import LangInfo

class RLangInfo(LangInfo):
    name = "R"
    conforms_to_bases = ["R"]
    exts = [".R", ".Rhistory", ".Rprofile"]
    filename_patterns = ["Rprofile"]
