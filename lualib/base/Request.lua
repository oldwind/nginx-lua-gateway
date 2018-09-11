-- ngx 模块变量
local ngx = ngx;


-- table 处理方法
local next   = next
local string = string;
local type   = type;

local pairs  = pairs

-- library utils
local utils = require("lualib.utils.Utils"); 

-- api 参数的封装返回 -- 
local request = {

	["method"] = "",

	["args_post"]   = {}, -- post 请求参数
	["args_get"]    = {}, -- get 请求参数
	["args"]        = {},  -- 请求参数 get和post合集

	["document_root"] = "", -- rewrite 前的文件根目录
	
	["request_uri"]   = "", -- 请求的uri，不带参数
	["document_uri"]  = "", -- rewrite 后的文件路径
	
	["http_referer"]    = "",
	["http_cookie"]     = {}, -- cookie 信息
	["http_user_agent"] = "",

	["remote_addr"] = "",  -- 客户端IP地址
	["scheme"]      = "",  -- http还是https

	["request_body_file"] = "", -- 客户端请求临时文件名


}



module(...)

-- 初始话请求
function parseRequest()

	-- 获取POST参数 必须先执行这个方法 
	ngx.req.read_body()


	request["method"] = ngx.req.get_method();

	-- post 参数
	local args, err = ngx.req.get_post_args()
	if args then 
		request["args_post"] = getBodyData()
	end

	-- get 参数
	request["args_get"]  = ngx.req.get_uri_args();


	-- 参数合并
	local params = request["args_get"]
	if next(request["args_post"]) ~= nil then 
		for k,v in pairs(request["args_post"]) do
			params[k] = v
		end
	end
	request["args"] = params;


	-- 解析URI
	local tbl_url = utils.explode("?", ngx.var.request_uri);
	local request_uri      = tbl_url[1];
	request["request_uri"] = request_uri;

	-- 
	request["document_root"] = ngx.var.document_root;
	
	request["document_uri"]  = ngx.var.document_uri;
	
	request["http_referer"]  = ngx.var.http_referer;

	request["remote_addr"] = ngx.var.remote_addr;
	
	request["scheme"]      = ngx.var.scheme;

	request["request_body_file"] = ngx.var.request_body_file;

	-- cookie 信息处理
	local http_cookie = getCookieTable(ngx.var.http_cookie)
	request["http_cookie"] = http_cookie;

end


-- 处理cookie字符串
function getCookieTable(cookies)
    local cookie_t   = {}
    local cookie_tbl = utils.explode("; ", cookies)

    if type(cookie_tbl) == 'table' then
        for __ , v in pairs(cookie_tbl) do
            local key, value = string.match(v, '^([^=]+)=(.*)$')
            if key and value then
                cookie_t[key] = value
            end
        end
    end
    return cookie_t
end


function getTblRequest() 
	return request
end


--获取body table
function getBodyData()
	local data = {}
	local boundary = getBoundary()
	local post = ngx.req.get_post_args()
	if type(post) == 'table' and next(post) then
		if not boundary then
			return post
		end
		data = post
		--if not string.find(post[next(post)], boundary) then
		--	return post
		--end
		post = ngx.req.get_body_data()
		if type(post) == 'string' then
			data = {}
			post = utils.explode(boundary, post)
			if type(post) == 'table' and next(post) then
				for __, v in pairs(post) do
					local tmp = utils.explode("\r\n\r\n", v)
					if type(tmp) == 'table' and tmp[2] then
						local name = string.match(tmp[1], "name=\"([^\"]+)\"") or tmp[1]
						local t = utils.explode("\r\n",tmp[2])
					    data[name] = t[1] or tmp[2]
				    end
				end
			end
		end
	end
	return data
end

--获取boundary
function getBoundary()
    local header = ngx.req.get_headers()["content-type"]
    if not header then
        return nil
    end 
        
    if type(header) == "table" then
        header = header[1]
    end         

    local m = string.match(header, ";%s*boundary=\"([^\"]+)\"")
    if m then
        return m
    end

    return string.match(header, ";%s*boundary=([^\",;]+)")
end

