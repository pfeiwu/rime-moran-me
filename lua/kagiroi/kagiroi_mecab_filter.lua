local Top = {}
local cache_size = 0
local MAX_CACHE_SIZE = 100

function Top.init(env)
    env.mem = Memory(env.engine, Schema("kagiroi"))
    env.kanafier = Component.Translator(env.engine, "", "script_translator@kagiroi_kana")
    env.pathsep = (package.config or '/'):sub(1, 1)
    env.base_path = rime_api.get_user_data_dir() .. env.pathsep .. "lua" .. env.pathsep .. "kagiroi"
    env.cache = setmetatable({}, { __mode = "v" }) -- 弱引用表
    env.mecab = package.loadlib(env.base_path .. env.pathsep .. "lua-mecab.so", "luaopen_mecab")
    if not env.mecab then
        error("Failed to load lua-mecab.so")
    end
    env.mecab = env.mecab()
    env.converter = env.mecab:new("-d " .. env.base_path .. env.pathsep .. "dic")
    env.smart_indicator = env.engine.schema.config:get_string("kagiroi/smart_indicator") or "🔥"
    env.tag = env.engine.schema.config:get_string("kagiroi/tag") or ""
end

function Top.func(t_input, env)
    local ctx = env.engine.context
    local segment = ctx.composition:back()
    if env.tag ~= "" then
        if not segment:has_tag(env.tag) then
            for cand in t_input:iter() do
                yield(cand)
            end
            return
        end
    end
    for cand in t_input:iter() do
        if cand:get_genuine().type == 'sentence' then
            local sentence_cand = cand:to_sentence()
            -- 保证我们只处理来自kagiroi的句子
            if sentence_cand.lang_name ~= "kagiroi" then
                yield(cand)
            else
                local new_entry = DictEntry(sentence_cand.entry)
                local active_text = segment:active_text(ctx.input)
                local kana_str = Top.query_kanafier(active_text, segment, env)
                new_entry.text = Top.query_mecab(kana_str, env)
                local new_cand = Phrase(env.mem, "mecab_phrase", cand.start, cand._end, new_entry):toCandidate()
                new_cand.comment = env.smart_indicator
                yield(new_cand)
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

function Top.query_kanafier(input, seg, env)
    local xlation = env.kanafier:query(input, seg)
    if xlation then
        local nxt, thisobj = xlation:iter()
        local cand = nxt(thisobj)
        if cand then
            return cand.text
        end
    end
    return ""
end

return Top
