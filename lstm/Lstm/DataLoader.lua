-- Author: Mengxi
-- Date: 2017.8.9

require 'hdf5'

local DataLoader = {}

-- return: {1:{path1, label1}, 2:{path2, label2} ..}
local function parseAnnotationFile(trainAnnotationFilePath)
	local trainAnnotationFile = io.open(trainAnnotationFilePath, 'r')
	local trainPathAndLabel = {}
	for strLine in trainAnnotationFile:lines() do
		local strVec = strLine:split(' ')
		local dataPath = strVec[1]
		local label = tonumber(strVec[2])
		
		table.insert(trainPathAndLabel, {dataPath, label})
	end
	
	trainAnnotationFile:close()
	
	return trainPathAndLabel
end
DataLoader.parseAnnotationFile = parseAnnotationFile

local function packAsTensor(inputList)
	local maxLength = 0
	for countSeq = 1, #inputList do
		if maxLength < inputList[countSeq]:size(1) then
			maxLength = inputList[countSeq]:size(1)
		end
	end
	
	local num = #inputList
	local dim = inputList[1]:size(2)
	
	local inputTensor = torch.Tensor(num, maxLength, dim):zero()
	inputTensor = inputTensor:cuda()
	
	local inputSizes = {}
	for countSeq = 1, #inputList do
		inputTensor[{{countSeq}, {1, inputList[countSeq]:size(1)}}]:copy(inputList[countSeq])
		table.insert(inputSizes, inputList[countSeq]:size(1))
	end
	
	return inputTensor, inputSizes
end

local function packAsTensorLabel(miniBatchLabel, seqMaxLen, miniBatchDataLen)
	assert(#miniBatchLabel == #miniBatchDataLen)
	local labelTensor = torch.Tensor(#miniBatchLabel, seqMaxLen):zero()
	labelTensor = labelTensor:cuda()
	
	for countSample = 1, labelTensor:size(1) do
		for countStep = 1, miniBatchDataLen[countSample] do
			labelTensor[countSample][countStep] = miniBatchLabel[countSample] 
		end
	end
	
	return labelTensor
end

-- miniBatchData: maxTimeLen x batchSize x inputDim, miniBatchLabels: maxTime x batchSize
local function loadData(dataPathsAndLabels, batchStart, batchEnd, datasetName)
	local miniBatchData = {}
	local miniBatchLabel = {}

	for countData = batchStart, batchEnd do
		assert(#(dataPathsAndLabels[countData]) == 2)
		local dataFile = hdf5.open(dataPathsAndLabels[countData][1], 'r')
		local data = dataFile:read(datasetName):all()
		dataFile:close()
		
		table.insert(miniBatchData, data)
		table.insert(miniBatchLabel, dataPathsAndLabels[countData][2])
	end
	
	local miniBatchDataLen
	miniBatchData, miniBatchDataLen = packAsTensor(miniBatchData)
	miniBatchLabel = packAsTensorLabel(miniBatchLabel, miniBatchData:size(2), miniBatchDataLen)
	
	miniBatchData = miniBatchData:transpose(1, 2):contiguous()
	miniBatchLabel = miniBatchLabel:transpose(1, 2):contiguous()
	

	return miniBatchData, miniBatchLabel, miniBatchDataLen
end
DataLoader.loadData = loadData

return DataLoader


