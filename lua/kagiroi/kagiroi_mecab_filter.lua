local Top = {}
local cache_size = 0
local MAX_CACHE_SIZE = 100

function Top.init(env)
    env.mem = Memory(env.engine, Schema("kagiroi"))
    env.pathsep = (package.config or '/'):sub(1, 1)
    env.base_path = rime_api.get_user_data_dir() .. env.pathsep .. "lua" .. env.pathsep .. "kagiroi"
    env.cache = setmetatable({}, { __mode = "v" }) -- 弱引用表
    env.mecab = package.loadlib(env.base_path .. env.pathsep .. "lua-mecab.so", "luaopen_mecab")
    if not env.mecab then
        error("Failed to load lua-mecab.so")
    end
    env.mecab = env.mecab()
    env.converter = env.mecab:new("-d " .. env.base_path .. env.pathsep .. "dic")
    -- todo 挂到主方案上
    env.prefix = env.engine.schema.config:get_string("kagiroi/prefix") or ""
    env.tips = env.engine.schema.config:get_string("kagiroi/tips") or ""
    env.candidate_tips = env.engine.schema.config:get_string("kagiroi/candidate_tips") or "🔥"
end

function Top.codepoints(word)
    local f, s, i = utf8.codes(word)
    local value = nil
    return function()
        i, value = f(s, i)
        if i then
            return i, value
        else
            return nil
        end
    end
end

---Return true if @str is purely Hiragana (including prolonged sound mark ー).
---@param str string
---@return boolean
function Top.str_is_hiragana(str)
    for _, cp in Top.codepoints(str) do
        -- Check if it's either hiragana range or the prolonged sound mark
        if not (
                (cp >= 0x3040 and cp <= 0x309F) or -- Hiragana range
                cp == 0x30FC                       -- Prolonged sound mark (ー)
            ) then
            return false
        end
    end
    return true
end

function Top.func(t_input, env)
    for cand in t_input:iter() do
        if cand:get_genuine().type == 'sentence' then
            -- 排除掉base码表输出的sentence
            if Top.str_is_hiragana(cand:to_sentence().entry.text) then
                local new_entry = DictEntry(cand:to_sentence().entry)
                new_entry.text = Top.query_mecab(new_entry.text, env)
                local new_cand = Phrase(env.mem, "mecab_phrase", cand.start, cand._end, new_entry):toCandidate()
                new_cand.comment = env.candidate_tips
                yield(Phrase(env.mem, "mecab_phrase", cand.start, cand._end, new_entry):toCandidate())
            end
        else
            yield(cand)
        end
    end
end

function Top.query_mecab(kana, env)
    -- 检查缓存
    local cached = env.cache[kana]
    if cached then
        return cached
    end
    local result
    result = env.converter:parse(kana)
    -- 更新缓存
    if cache_size < MAX_CACHE_SIZE then
        env.cache[kana] = result
        cache_size = cache_size + 1
    end
    return result
end

return Top
