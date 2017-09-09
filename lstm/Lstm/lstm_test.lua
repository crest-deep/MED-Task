-- Original Author: Na
-- Refactor Author: Mengxi
-- Refactor date: 2017.8.14

--sequence x batch x featdim
require 'cutorch'
require 'cunn'
require 'rnn'
require 'optim'

torch.setdefaulttensortype('torch.FloatTensor')

local DataLoader = require 'DataLoader'
local Scorer = require 'Scorer'

local testAnnotationFilePath = arg[1]
local datasetName = arg[2]

local modelPath = arg[3]
local batchSize = tonumber(arg[4])

local outputPath = arg[5]

local gpuId = tonumber(arg[6])

cutorch.setDevice(gpuId)

local timerTotal = torch.Timer()
print("Loading model...")
print(modelPath)
local model = torch.load(modelPath)
model = model:cuda()

--SoftMax Layer
local softMaxLayer = nn.Sequencer(nn.MaskZero(nn.SoftMax(), 1))
softMaxLayer = softMaxLayer:cuda()

print("Model Loaded...")

-- dataPathsAndLabels: { 1:{path1, label1}, 2:{path2, label2}, ...}
local dataPathsAndLabels = DataLoader.parseAnnotationFile(testAnnotationFilePath)
local testNum = #dataPathsAndLabels
print("#TestNum: ", testNum)

local batchNum = math.ceil(testNum / batchSize)
print('Total BatchNum: ', batchNum)
local finalResAvg = torch.Tensor()
finalResAvg = finalResAvg:cuda()
for countBatch = 1, batchNum do
	local batchStart = (countBatch - 1) * batchSize + 1
	local batchEnd = (batchStart + batchSize - 1 > testNum) and (testNum) or (batchStart + batchSize - 1)
	
	-- miniBatchData: maxTimeLen x batchSize x inputDim
	local miniBatchData, _, miniBatchLen = DataLoader.loadData(dataPathsAndLabels, batchStart, batchEnd, datasetName)
	
	-- forward
	local miniAct = model:forward(miniBatchData)
	local miniSoftMax = softMaxLayer:forward(miniAct)
	
	-- take average of softmax
	local miniSoftMaxAvg = Scorer.takeAvgStep(miniSoftMax, miniBatchLen)
	finalResAvg = finalResAvg:cat(miniSoftMaxAvg, 1)
	print('Finish Batch: ', countBatch)	
end

finalResAvg = finalResAvg:float()
local outfile = hdf5.open(outputPath, 'w')
outfile:write('data', finalResAvg)	
outfile:close()
print('Time elapsed: ' .. timerTotal:time().real .. ' seconds')

