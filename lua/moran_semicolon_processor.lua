-- moran_semicolon_processor.lua
-- Synopsis: 選擇第二個首選項，但可用於跳過 emoji 濾鏡產生的候選
-- Author: ksqsf
-- Modified by kuroame, points:
-- 1. make it compatible with huma-style 快符.
-- 2. if it's the first 选重, disregard candidates that do not match the whole input to improve determinacy.
-- 3. fallback to first candidate
-- License: MIT license
-- Version: 0.1.2

-- NOTE: This processor depends on, and thus should be placed before,
-- the built-in "selector" processor.

local moran = require("moran")

local kReject = 0
local kAccepted = 1
local kNoop = 2
local semicolon_codepoint =   utf8.codepoint("；", 1)
local colon_codepoint =   utf8.codepoint("：", 1)
local function processor(key_event, env)
   local context = env.engine.context

   if key_event.keycode ~= 0x3B or key_event:release() then
      return kNoop
   end

   local composition = context.composition
   if composition:empty() then
      return kNoop
   end

   local segment = composition:back()
   local menu = segment.menu

   -- Special case: if there is only one candidate, just select it!
   if menu:candidate_count() == 1 then
      env.engine:process_key(KeyEvent("1"))
      return kAccepted
   end

   -- If it is not the first page, simply send 2.
   local page_size = env.engine.schema.page_size
   local selected_index = segment.selected_index
   if selected_index >= page_size then
      env.engine:process_key(KeyEvent("2"))
      return kAccepted
   end

   -- First page: do something more sophisticated.
   local i = 1
   while i < page_size do
      local cand = menu:get_candidate_at(i)
      local cand_text = cand.text
      local cand_start = cand.start
      local cand_end = cand._end
      local cand_length = cand_end - cand_start
      local codepoint = utf8.codepoint(cand_text, 1)
      if (cand_start ~= 0 or cand_length == #context.input)   -- cand_length should equal to input_length when no candidate is selected
      and (
         moran.unicode_code_point_is_chinese(codepoint)
         or (codepoint >= 97 and codepoint <= 122)
         or (codepoint >= 65 and codepoint <= 90)
         or codepoint == colon_codepoint or codepoint == semicolon_codepoint -- in case of ; 快符
      )
      then
         env.engine:process_key(KeyEvent(tostring(i+1)))
         return kAccepted
      end
      i = i + 1
   end

   -- No good candidates found. Just select the first candidate.
   env.engine:process_key(KeyEvent("1"))
   return kAccepted
end

return processor
