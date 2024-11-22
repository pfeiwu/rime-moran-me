-- kagiroi_translator.lua
-- 使用mecab+mozc词库提供日语智能候选
-- todo： 支持用户输入历史，userdb？
local Top = {}

function Top.init(env)
    env.romajifier = Component.Translator(env.engine, "", "script_translator@kagiroi")
    env.pathsep = (package.config or '/'):sub(1, 1)
    env.base_path = rime_api.get_user_data_dir() .. env.pathsep .. "lua" .. env.pathsep .. "kagiroi"
    env.mecab = package.loadlib(env.base_path .. env.pathsep .. "lua-mecab.so", "luaopen_mecab")
    if not env.mecab then
        error("Failed to load lua-mecab.so")
    end
    env.mecab = env.mecab()
    env.parser = env.mecab:new("-d " .. env.base_path .. env.pathsep .. "dic")
    env.candidate_num = env.engine.schema.config:get_int("kagiroi/smart_candidate_num") or 10
    env.prefix = env.engine.schema.config:get_string("kagiroi/prefix") or ""
    env.tips = env.engine.schema.config:get_string("kagiroi/tips") or ""
end

function Top.fini(env)
end

function Top.func(input, seg, env)
    local ctx = env.engine.context
    local len = #ctx.input
    if env.prefix ~= "" then
        if input:sub(1, #env.prefix) == env.prefix then
            input = input:sub(#env.prefix + 1)
        else
            return
        end
    end
    if #input == 0 then
        ctx.composition:back().prompt = env.tips
        return
    end
    local xlation = env.romajifier:query(input, seg)
    if xlation then
        local nxt, thisobj = xlation:iter()
        local cand = nxt(thisobj)
        if cand then
            local text = cand.text
            local result = env.parser:parseNBest(text, env.candidate_num)
            for _, line in ipairs(result) do
                yield(Candidate("mecab", 0, len, line, ""))
            end
        end
    end
end

return Top
