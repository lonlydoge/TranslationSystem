local googlev = isfile 'googlev.txt' and readfile 'googlev.txt' or ''
local reqid = math.random(1000, 9999)

local rootURL = "https://translate.google.com/"
local executeURL = "https://translate.google.com/_/TranslateWebserverUi/data/batchexecute"

local System = {}

local languages = {
    auto = "Automatic",
    af = "Afrikaans",
    sq = "Albanian",
    am = "Amharic",
    ar = "Arabic",
    hy = "Armenian",
    az = "Azerbaijani",
    eu = "Basque",
    be = "Belarusian",
    bn = "Bengali",
    bs = "Bosnian",
    bg = "Bulgarian",
    ca = "Catalan",
    ceb = "Cebuano",
    ny = "Chichewa",
    ['zh-cn'] = "Chinese Simplified",
    ['zh-tw'] = "Chinese Traditional",
    co = "Corsican",
    hr = "Croatian",
    cs = "Czech",
    da = "Danish",
    nl = "Dutch",
    en = "English",
    eo = "Esperanto",
    et = "Estonian",
    tl = "Filipino",
    fi = "Finnish",
    fr = "French",
    fy = "Frisian",
    gl = "Galician",
    ka = "Georgian",
    de = "German",
    el = "Greek",
    gu = "Gujarati",
    ht = "Haitian Creole",
    ha = "Hausa",
    haw = "Hawaiian",
    iw = "Hebrew",
    hi = "Hindi",
    hmn = "Hmong",
    hu = "Hungarian",
    is = "Icelandic",
    ig = "Igbo",
    id = "Indonesian",
    ga = "Irish",
    it = "Italian",
    ja = "Japanese",
    jw = "Javanese",
    kn = "Kannada",
    kk = "Kazakh",
    km = "Khmer",
    ko = "Korean",
    ku = "Kurdish (Kurmanji)",
    ky = "Kyrgyz",
    lo = "Lao",
    la = "Latin",
    lv = "Latvian",
    lt = "Lithuanian",
    lb = "Luxembourgish",
    mk = "Macedonian",
    mg = "Malagasy",
    ms = "Malay",
    ml = "Malayalam",
    mt = "Maltese",
    mi = "Maori",
    mr = "Marathi",
    mn = "Mongolian",
    my = "Myanmar (Burmese)",
    ne = "Nepali",
    no = "Norwegian",
    ps = "Pashto",
    fa = "Persian",
    pl = "Polish",
    pt = "Portuguese",
    pa = "Punjabi",
    ro = "Romanian",
    ru = "Russian",
    sm = "Samoan",
    gd = "Scots Gaelic",
    sr = "Serbian",
    st = "Sesotho",
    sn = "Shona",
    sd = "Sindhi",
    si = "Sinhala",
    sk = "Slovak",
    sl = "Slovenian",
    so = "Somali",
    es = "Spanish",
    su = "Sundanese",
    sw = "Swahili",
    sv = "Swedish",
    tg = "Tajik",
    ta = "Tamil",
    te = "Telugu",
    th = "Thai",
    tr = "Turkish",
    uk = "Ukrainian",
    ur = "Urdu",
    uz = "Uzbek",
    vi = "Vietnamese",
    cy = "Welsh",
    xh = "Xhosa",
    yi = "Yiddish",
    yo = "Yoruba",
    zu = "Zulu"
};

function find(lang)
    for i, v in pairs(languages) do
        if i == lang or v == lang then
            return i
        end
    end
end

function isSupported(lang)
    local key = find(lang)
    return key and true or false
end

function getISOCode(lang)
    local key = find(lang)
    return key
end

local function got(url, Method, Body) -- Basic version of https://www.npmjs.com/package/got using synapse's request API for google websites
    Method = Method or "GET"

    local res = syn and syn.request or request({
        Url = url,
        Method = Method,
        Headers = {
            cookie = "CONSENT=YES+" .. googlev
        },
        Body = Body
    })

    if res.Body:match('https://consent.google.com/s') then
        googleConsent(res.Body)
        res = syn and syn.request or request({
            Url = url,
            Method = "GET",
            Headers = {
                cookie = "CONSENT=YES+" .. googlev
            }
        })
    end

    return res
end

local fsid, bl

do -- init
    local InitialReq = got(rootURL)
    fsid = InitialReq.Body:match('"FdrFJe":"(.-)"')
    bl = InitialReq.Body:match('"cfb2h":"(.-)"')
end

function googleConsent(Body) -- Because google really said: "Fuck you."
    local args = {}

    for match in Body:gmatch('<input type="hidden" name=".-" value=".-">') do
        local k, v = match:match('<input type="hidden" name="(.-)" value="(.-)">')
        args[k] = v
    end
    googlev = args.v
    writefile('googlev.txt', args.v)
end

local HttpService = game:GetService("HttpService")

function jsonE(o)
    return HttpService:JSONEncode(o)
end
function jsonD(o)
    return HttpService:JSONDecode(o)
end

function stringifyQuery(dataFields)
    local data = ""
    for k, v in pairs(dataFields) do
        if type(v) == "table" then
            for _, v in pairs(v) do
                data = data .. ("&%s=%s"):format(game.HttpService:UrlEncode(k), game.HttpService:UrlEncode(v))
            end
        else
            data = data .. ("&%s=%s"):format(game.HttpService:UrlEncode(k), game.HttpService:UrlEncode(v))
        end
    end
    data = data:sub(2)
    return data
end

function translate(str, to, from)
    reqid = reqid + 10000
    from = from and getISOCode(from) or 'auto'
    to = to and getISOCode(to) or 'en'

    local data = {{str, from, to, true}, {nil}}

    local freq = {{{"MkEWBc", jsonE(data), nil, "generic"}}}
    local url = executeURL .. '?' .. stringifyQuery {
        rpcids = "MkEWBc",
        ['f.sid'] = fsid,
        bl = bl,
        hl = "en",
        _reqid = reqid - 10000,
        rt = 'c'
    }
    local body = stringifyQuery {
        ['f.req'] = jsonE(freq)
    }

    local req = got(url, "POST", body)

    local body = jsonD(req.Body:match '%[.-%]\n')
    local translationData = jsonD(body[1][3])
    local result = {
        text = "",
        from = {
            language = "",
            text = ""
        },
        raw = ""
    }
    result.raw = translationData
    result.text = translationData[2][1][1][6][1][1]

    result.from.language = translationData[3]
    result.from.text = translationData[2][5][1]

    return result
end

function System.translateFrom(message)
    local translation = translate(message, YourLang)

    return translation.text
end

return System
