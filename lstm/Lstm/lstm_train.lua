-- Original Author: Na
-- Refactor Author: Mengxi
-- Refactor date: 2017.8.9

--time x batch x featdim
require 'cutorch'
require 'cunn'
require 'rnn'
require 'optim'

torch.setdefaulttensortype('torch.FloatTensor')

local NetworkConstructor = require 'NetworkConstructor'
local DataLoader = require 'DataLoader'

local trainAnnotationFilePath = arg[1]
local datasetName = arg[2]

local inputDim = tonumber(arg[3])
local outputDim = tonumber(arg[4])
local hiddenDim = tonumber(arg[5])

local modelSavingDir = arg[6]
local modelSavingStep = tonumber(arg[7])
local epochNum = tonumber(arg[8])
local batchSize = tonumber(arg[9])
local lr = tonumber(arg[10])
local lrd = tonumber(arg[11])
local wd = tonumber(arg[12])
local gradientClip = tonumber(arg[13])

local gpuId = tonumber(arg[14])

cutorch.setDevice(gpuId)

local timerTotal = torch.Timer()

print('Creating model...')
-- local hiddenLayerNum = 1
-- Input: time x batch x inputDim, Output: time x batch x outputDim
local model = NetworkConstructor.constructLSTM(inputDim, hiddenDim, outputDim)
model = model:cuda()
-- Flatten the parameters and gradients of the model for 'optim' updating
local params, grads = model:getParameters()

--LogSoftMax Layer
local logSoftMaxLayer = nn.Sequencer(nn.MaskZero(nn.LogSoftMax(), 1))
logSoftMaxLayer = logSoftMaxLayer:cuda()

-- Criterion
local weight = torch.Tensor(outputDim):fill(1)
local criterion = nn.SequencerCriterion(nn.MaskZeroCriterion(nn.ClassNLLCriterion(weight), 1))
criterion = criterion:cuda()

local optimParams = {
	learningRate = lr,
	learningRateDecay = lrd,
	weightDecay = wd,
	--momentum = momentum
}
print('Model created')

-- dataPathsAndLabels: { 1:{path1, label1}, 2:{path2, label2}, ...}
local dataPathsAndLabels = DataLoader.parseAnnotationFile(trainAnnotationFilePath)
local trainNum = #dataPathsAndLabels
print("#trainSample: ", trainNum)

local timerEpoch = torch.Timer()
local batchNum = math.ceil(trainNum / batchSize)
for countEpoch = 1, epochNum do
	timerEpoch:reset()
	
	for countBatch = 1, batchNum do
		local batchStart = (countBatch - 1) * batchSize + 1
		local batchEnd = (batchStart + batchSize - 1 > trainNum) and (trainNum) or (batchStart + batchSize - 1)
		
		-- miniBatchData: maxTimeLen x batchSize x inputDim, miniBatchLabels: maxTime x batchSize
		local miniBatchData, miniBatchLabels = DataLoader.loadData(dataPathsAndLabels, batchStart, batchEnd, datasetName)
		
		-- forward
		local miniAct = model:forward(miniBatchData)
		local miniLogSoft = logSoftMaxLayer:forward(miniAct)
		local loss = criterion:forward(miniLogSoft, miniBatchLabels)
		
		-- backward
		local gradSoftmax = criterion:backward(miniLogSoft, miniBatchLabels)
		local gradAct = logSoftMaxLayer:backward(miniAct, gradSoftmax)
		
		model:zeroGradParameters()
		model:backward(miniBatchData, gradAct)
		
		-- gradient clipping
		grads:clamp(-gradientClip, gradientClip)

		-- update params
		local function feval(params)
			return loss, grads
		end
		optim.adam(feval, params, optimParams)
		
		print("Loss: " .. loss .. " " .. "[Epoch: " .. countEpoch .. "]" .. "[Batch: " .. countBatch .. "]")
	end
	
	print("Time[Epoch " .. countEpoch .. "]: " .. timerEpoch:time().real)
	
	if countEpoch % modelSavingStep == 0 or countEpoch == epochNum then
		print("saving model-epoch:" .. countEpoch)
		model:clearState()
		torch.save(string.format("%s/model_100ex_batch%d_unit%d_epoch%d", modelSavingDir, batchSize, hiddenDim, countEpoch), model)
	end
	
end

print("Total Time Elapsed: " .. timerTotal:time().real)
