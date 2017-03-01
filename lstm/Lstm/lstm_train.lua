--sequence x batch x featdim
--right-aligned
require 'cutorch'
require 'cunn'
require 'rnn'
require 'optim'
require 'hdf5'

local trainAnnotationPath = arg[1]
local trainNum = tonumber(arg[2])

local featdim = tonumber(arg[3])
local seqLengthMax = tonumber(arg[4])
local numTargetClasses = tonumber(arg[5])
local hiddenSize = tonumber(arg[6]) --128

local modelSavingDir = arg[7]
local modelSavingStep = tonumber(arg[8])
local epoch = tonumber(arg[9])
local batchSize = tonumber(arg[10]) --5
local lr = tonumber(arg[11]) -- 0.005
local lrd = tonumber(arg[12])
local wd = tonumber(arg[13])
local momentum = tonumber(arg[14])

local gpuId = tonumber(arg[15])

cutorch.setDevice(gpuId + 1)

local timer = torch.Timer()
print('Creating model...')
--[[local model = nn.Sequencer(
	nn.Sequential()
		:add(nn.MaskZero(nn.FastLSTM(featdim,hiddenSize),1))
		:add(nn.MaskZero(nn.Linear(hiddenSize, numTargetClasses),1))
		:add(nn.MaskZero(nn.LogSoftMax(),1))
)--]]
local model = nn.Sequencer(
	nn.Sequential()
		:add(nn.FastLSTM(featdim, hiddenSize):maskZero(1))
		:add(nn.MaskZero(nn.Linear(hiddenSize, numTargetClasses),1))
		:add(nn.MaskZero(nn.LogSoftMax(),1))
)

local weight = torch.Tensor(21):fill(1)
weight[21] = 0.02   -- the training samples of class21 is around 5000, while training samples of other classes is 100.
local criterion = nn.SequencerCriterion(nn.MaskZeroCriterion(nn.ClassNLLCriterion(weight),1))

model:cuda()
criterion:cuda()
local bactchseqLenMax = 0
local bactchseqLens = torch.Tensor(batchSize):fill(0)
local feattemp = torch.Tensor(batchSize, seqLengthMax, featdim):fill(0)
local labelbatch = torch.Tensor(batchSize):fill(0)
local targets = {}

local sgd_params = {
	learningRate = lr,
	learningRateDecay = lrd,
	weightDecay = wd,
	momentum = momentum
}
-- get weights and loss wrt weights from the model
local params, grads = model:getParameters()
print('Model created')

local allnum = 0
for epi = 1, epoch do
	local linenum = 0
	for line in io.lines(trainAnnotationPath) do
		linenum = linenum + 1
		allnum = trainNum * (epi - 1) + linenum
		print("epoch:"..epi..", linenum:"..linenum)
		local i = allnum % batchSize
		if i == 0 then 
			i = batchSize 
		end
		local featpath = line:split(' ')[1]
		local labeli = line:split(' ')[2]
		labelbatch[i] = tonumber(labeli)

		--dirs
		local myFile = hdf5.open(featpath, 'r')
		local data = myFile:read('feature'):all()
		bactchseqLens[i] = data:size(1)
		if bactchseqLens[i] > seqLengthMax then
			data = data[{{1,seqLengthMax}}]
			bactchseqLens[i] = seqLengthMax
		end
		feattemp[i][{{1,bactchseqLens[i]}, {}}] = data
		if (i == batchSize) then
			--for last batch
			bactchseqLenMax = torch.max(bactchseqLens)
			local input = {} 
			local targets = {}
			local seqPadding = torch.Tensor(batchSize):fill(bactchseqLenMax)-bactchseqLens

			----right-aligned, padding zero in the left
			local forOneTimeStep
			local labeltemp
			for seq = 1, bactchseqLenMax do
				forOneTimeStep = torch.Tensor(batchSize,featdim):fill(0)
				labeltemp = torch.Tensor(batchSize):fill(0)
				forOneTimeStep = forOneTimeStep:cuda()
				labeltemp = labeltemp:cuda()
				for batchi = 1, batchSize do
					if seqPadding[batchi] < seq then
						forOneTimeStep[batchi]=feattemp[batchi][seq-seqPadding[batchi]]
						labeltemp[batchi]=labelbatch[batchi]
					end
				end
				table.insert(input,forOneTimeStep)
				table.insert(targets, labeltemp)
			end
			----RNN	   	    
			local feval = function(x_new)
				-- copy the weight if are changed
				if params ~= x_new then
					params:copy(x_new)
				end
				-- reset gradients (gradients are always accumulated, to accommodate
				-- batch methods)
				grads:zero()

				-- evaluate the loss function and its derivative with respect to x, given a mini batch
				local output = model:forward(input)

				local loss_x = criterion:forward(output, targets)
				local gradOutputs = criterion:backward(output, targets)
				model:backward(input, gradOutputs)
				return loss_x, grads
			end
			local _, fs = optim.sgd(feval, params, sgd_params)
			print("Loss: " .. fs[1])
			bactchseqLenMax = 0
			bactchseqLens = torch.Tensor(batchSize):fill(0)
			feattemp = torch.Tensor(batchSize, seqLengthMax, featdim):fill(0)
			labelbatch = torch.Tensor(batchSize):fill(0)	    
		end
	end
	io.input():close()
	if (epi > modelSavingStep and epi % modelSavingStep == 0) then
		print("saving model-epoch:".. epi)
		print('Time elapsed: ' .. timer:time().real .. ' seconds')
		collectgarbage("collect")
		model:clearState()
		torch.save(string.format("%s/model_100ex_batch%d_unit%d_epoch%d", modelSavingDir, batchSize, hiddenSize, epi), model)
	end
end
model:clearState()
torch.save("rnnmodel_100ex-all", model)
print("finish training!")
print('Time elapsed: ' .. timer:time().real .. ' seconds')
