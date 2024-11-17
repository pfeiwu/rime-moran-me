-- moran_quick_code_emoji_hint.lua
-- just for fun

local Module = {}
local moran = require("moran")

function Module.init(env)
  env.emojifier = Opencc("moran_emoji.json")
  env.quick_code_indicator = env.engine.schema.config:get_string("moran/quick_code_indicator") or "⚡"
end

function Module.fini(env)
end

function Module.func(translation, env)
   for cand in translation:iter() do
      -- 因为此filter在simplifier@emoji后面，此时type是simplified应当都是emoji内容
      -- 由于重叠两个emoji不太好看，这里放一个空comment的candidate
      if cand.type == "simplified" then
         yield(Candidate("emoji", cand.start, cand._end, cand.text, ""))
         goto continue
      end
      local gcand = cand:get_genuine()
      -- 利用moran的emoji滤镜的opencc配置，得到一个emoji提示符，替换掉原有的提示符，如果没有找到，仍使用schema设置的提示符
      if gcand.comment:find(env.quick_code_indicator) then
         local emoji_candidates = env.emojifier:convert_word(gcand.text)
         if emoji_candidates ~= nil then
            gcand.comment = gcand.comment:gsub(env.quick_code_indicator, emoji_candidates[math.random(2, #emoji_candidates)])
         end
      end
      yield(cand)
      ::continue::
   end
end

return Module
