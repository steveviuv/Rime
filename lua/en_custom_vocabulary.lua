local user_data_dir = string.gsub(rime_api:get_user_data_dir(),"/","//")
local shared_data_dir = string.gsub(rime_api:get_shared_data_dir(),"/","//")
local dict_name = "/en_dicts/en_custom.txt"

-- 检查文件是否存在并获取词典路径
local dict_dir = nil
if (io.open(user_data_dir..dict_name,"r")) then
  dict_dir = user_data_dir..dict_name
else
  if (io.open(shared_data_dir..dict_name,"r")) then
    dict_dir = shared_data_dir..dict_name
  else 
    return
  end
end

-- 动态读取词典文件的函数
local function read_custom_dict()
  local words = {}
  local file = io.open(dict_dir, "r")
  if file then
    for line in file:lines() do
      -- 跳过注释行和空行
      if not line:match("^%s*#") and line:match("%S") then
        local word = line:match("^(%S+)")
        if word and not word:match("^#@") then
          words[word:lower()] = true
        end
      end
    end
    file:close()
  end
  return words
end

-- 检查词是否存在于词典文件中
local function user_dict_exists_(word, dict_path)
  local file = io.open(dict_path, "r")
  if file then
    local content = file:read("*all")
    file:close()
    return content:find("\n" .. word .. "\t") or content:find("^" .. word .. "\t")
  end
  return false
end

-- 自定义词汇转换器
local function translator(input, seg, env)
  -- 获取输入末尾的反引号
  local inp = string.match(input, "(.+)`$")
  if inp then
    -- 反引号作为添加词的标记
    local unconfirm = inp:gsub(" ", "")
    
    if user_dict_exists_(unconfirm, dict_dir) then
      -- 词已存在，提示删除
      local file = io.open(dict_dir, "r+")
      local content = file:read("*all")
      file:close()
      content = content:gsub("\n" .. unconfirm .. "\t" .. unconfirm .. "\t%d+", "")
      file = io.open(dict_dir, "w+")
      file:write(content)
      file:close()
      yield(Candidate("en_custom", seg.start, seg._end, inp, "✅"))
    else
      -- 添加新词
      local file = io.open(dict_dir, "a")
      file:write("\n" .. unconfirm .. "\t" .. unconfirm .. "\t100000")
      file:close()
      yield(Candidate("en_custom", seg.start, seg._end, inp, "✅"))
    end
  else
    -- 动态检查输入是否匹配词典中的词
    local words = read_custom_dict()
    local input_lower = input:lower()
    
    -- 检查前缀匹配
    for word in pairs(words) do
      if word:sub(1, #input_lower) == input_lower then
        yield(Candidate("en_custom", seg.start, seg._end, word, "〔自定义〕"))
      end
    end
  end
end

return translator