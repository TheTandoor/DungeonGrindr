local addonName, T = ...;

T.Funcs = {}

function T.Funcs:print(...)
	print(...)
end

function T.Funcs:LFGListGetSearchResultInfo(...)
	return C_LFGList.GetSearchResultInfo(...)
end

function T.Funcs:GetSearchResultLeaderInfo(...)
	return C_LFGList.GetSearchResultLeaderInfo(...)
end

function T.Funcs:GetActivityInfoTable(...)
	return C_LFGList.GetActivityInfoTable(...)
end

function T.Funcs:GetFilteredSearchResults(...)
	return C_LFGList.GetFilteredSearchResults(...)
end

function T.Funcs:GetActiveEntryInfo(...)
	return C_LFGList.GetActiveEntryInfo(...)
end

function T.Funcs:Search(...)
	return C_LFGList.Search(...)
end

function T.Funcs:HasActiveEntryInfo(...)
	return C_LFGList.HasActiveEntryInfo(...)
end

function T.Funcs:GetAvailableActivities(...)
	return C_LFGList.GetAvailableActivities(...);
end