
local BasicOperations = {}

local function getFilePaths(dirPath)
	local filePaths = {}
	
	local filePathsOrigin = paths.dir(dirPath)
	for count = 1, #filePathsOrigin do
		if filePathsOrigin[count] ~= '.' and filePathsOrigin[count] ~= '..' then
			table.insert(filePaths, dirPath .. filePathsOrigin[count])
		end
	end
	table.sort(filePaths)
	
	return filePaths
end
BasicOperations.getFilePaths = getFilePaths

return BasicOperations
