
--[[******
 * Copyright by yebin
 *
 * ActionController.lua
 *
 * @package framework
 * @authors yebin
 * @date    2017-07-22 16:43:38
 * @version 1.0
 */
]]

local string = require("string")
local pairs = pairs
local print = print
local tostring   = tostring
local type  = type
local require = require
local error = error
local utils = require("lualib.utils.Utils")
local preg_match = ngx.re.match

--[[
/**
 * module name
 */
]]
module(...)

local ruleConfig    = {}
local hashMapping   = {}
local prefixMapping = {}
local regexMapping  = {}


function initial(self, config)
	self.ruleConfig    = config['rule_config'] or {}
	self.hashMapping   = config['hash_mapping'] or {}
	self.prefixMapping = config['prefix_mapping'] or {}
	self.regexMapping  = config['regex_mapping'] or {}
	return true
end


local function parseRequestUri(uri, ignoredDirs)
	if ((not ignoredDirs) or ignoredDirs < 0) then
		ignoredDirs = 0
	end
	
	local len = string.find(uri, '?')
	if len then
		uri = string.sub(uri, 1, len - 1)
	end
	return string.lower(uri)
end


local function getDispatchedActionInfo(self, request_uri)
	local uri = request_uri or ""
	local ignoredDirs = self.ruleConfig['begindex'] or 0
	local parsedUri   = parseRequestUri(uri, ignoredDirs)
	local actionConfig = ""
	local actionParams = {}
	
	if (self.hashMapping[parsedUri]) then
		actionConfig    = self.hashMapping[parsedUri]
		actionClassName = actionConfig[1]
		actionParams    = actionConfig[2] or {}
		return actionClassName, actionParams
	end
	
	for pattern,actionConfig in pairs(self.prefixMapping) do
		if (utils.prefix_match(parsedUri, pattern)) then
			actionClassName = actionConfig[1]
			actionParams    = actionConfig[2] or {}
			return actionClassName, actionParams
		end
	end
	
	for pattern,actionConfig in pairs(self.regexMapping) do
		if (preg_match(uri, pattern)) then
			actionClassName = actionConfig[1]
			actionParams    = actionConfig[2] or {}
			return actionClassName, actionParams
		end
	end
	
	local errmsg = 'No action could be dispatched for uri: ' .. uri
	return nil, nil, errmsg
end

local function getModuleAction(actionClassName)
	if (not actionClassName
		or (not string.find(actionClassName, "^[%a_][%w_%-.]*$"))) then
		errmsg = 'action class name invalid: actionClassName['..actionClassName..']'
		return nil, errmsg
	end
	return require(actionClassName)
end

function execute(self, request_uri)
	local actionClassName,actionParams,errmsg = getDispatchedActionInfo(self, request_uri)
	if errmsg then 
		error(errmsg)
	end

	if (actionClassName) then
		local actionObject,errmsg = getModuleAction(actionClassName)
		if errmsg then
			error(errmsg)
		end
		return actionObject.execute(actionParams)
	end
	return false
end
